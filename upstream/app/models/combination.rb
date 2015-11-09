require 'combination/detection'

class Combination < FingerbankModel
  belongs_to :dhcp_fingerprint
  belongs_to :dhcp6_fingerprint
  belongs_to :dhcp6_enterprise
  belongs_to :user_agent
  belongs_to :dhcp_vendor
  belongs_to :device
  belongs_to :mac_vendor

  belongs_to :submitter, :class_name => "User"

  has_many :query_log

  attr_accessor :processed_method

  validates_presence_of :dhcp_fingerprint_id, :dhcp6_fingerprint_id, :dhcp6_enterprise_id, :dhcp_vendor_id, :user_agent_id
  validate :validate_combination_uniqueness

  scope :unknown, -> {where(:device => nil)}   
  scope :known, -> {where('device_id is not null')}   
  scope :unrated, -> {where('device_id is not null and score=0')}   

  def self.simple_search_joins
    return {
      :has => [],
      :belongs_to => [
        :dhcp_fingerprint,
        :dhcp6_fingerprint,
        :dhcp6_enterprise,
        :user_agent,
        :dhcp_vendor,
        :mac_vendor,
        :device,
        :submitter,
      ],
      :ignore => [
        'submitters.key'
      ]
    }
  end

  def just_created
    if @just_created
      true
    else
      false
    end
  end

  def just_created=(value)
    @just_created = value
  end

  def self.get_or_create(values)
    combination = nil
    Combination.transaction do
      dhcp_fingerprint = DhcpFingerprint.get_or_create(:value => values[:dhcp_fingerprint])
      dhcp6_fingerprint = Dhcp6Fingerprint.get_or_create(:value => values[:dhcp6_fingerprint])
      dhcp6_enterprise = Dhcp6Enterprise.get_or_create(:value => values[:dhcp6_enterprise])
      dhcp_vendor = DhcpVendor.get_or_create(:value => values[:dhcp_vendor])
      user_agent = UserAgent.get_or_create(:value => values[:user_agent])
      mac_vendor = MacVendor.from_mac(values[:mac])
      combination = Combination.where(:dhcp_fingerprint_id => dhcp_fingerprint.id, :dhcp6_fingerprint_id => dhcp6_fingerprint.id, :dhcp6_enterprise_id => dhcp6_enterprise.id, :user_agent_id => user_agent.id, :dhcp_vendor_id => dhcp_vendor.id, :mac_vendor => mac_vendor).first
      if combination.nil?
        begin
          combination = self.create!(:dhcp_fingerprint => dhcp_fingerprint, :dhcp6_fingerprint => dhcp6_fingerprint, :dhcp6_enterprise_id => dhcp6_enterprise.id, :user_agent => user_agent, :dhcp_vendor => dhcp_vendor, :mac_vendor => mac_vendor)
          combination.just_created = true
          return combination
        rescue
          if values[:retrying]
            logger.info "Failed to get_or_create combination twice, will not try again"
            return nil
          else
            logger.info "Failed to get_or_create combinaton once, will try again."
            values[:retrying] = true
            return self.get_or_create(values)
          end
        end
      end
    end
  end

  def validate_combination_uniqueness
    existing = Combination.where(:dhcp_fingerprint_id => dhcp_fingerprint_id, :dhcp6_fingerprint_id => dhcp6_fingerprint_id, :dhcp6_enterprise_id => dhcp6_enterprise_id, :user_agent_id => user_agent_id, :dhcp_vendor_id => dhcp_vendor_id, :mac_vendor_id => mac_vendor_id).size
    if (persisted? && existing > 1) || (!persisted? && existing > 0)
      logger.warn "Combination #{id} was going to be saved, but a duplicate was found with dhcp_fingerprint_id #{dhcp_fingerprint_id}, dhcp6_fingerprint_id #{dhcp6_fingerprint_id}, :dhcp6_enterprise_id #{dhcp6_enterprise_id}, user_agent_id #{user_agent_id}, dhcp_vendor_id #{dhcp_vendor_id}, mac_vendor_id #{mac_vendor_id}"
      errors.add(:combination, 'A unique set of attributes must be set. This combination already exists')
    end
  end

  def validate_submition
    if device.nil?
      errors.add(:device, 'cannot be empty')
    end
    if version.nil? or version.empty?
      errors.add(:version, 'cannot be empty')
    end
    return errors.empty?
  end

  def self.score_from_discoverers(discoverers)
    disc_per_device = {}
    score_per_device = {} 
    discoverers.each do |discoverer| 
      disc_per_device[discoverer.device] = [] if disc_per_device[discoverer.device].nil?
      disc_per_device[discoverer.device] << discoverer

    end
    disc_per_device.each do |device, discoverers|
      total = device.discoverers.size
      matched = discoverers.size
      
      score = 0
      discoverers.each{|discoverer| score += discoverer.priority}
      device.parents.each do |parent|
        if disc_per_device.has_key? parent
          disc_per_device[parent].each{|discoverer| score += discoverer.priority}
        end
      end
      logger.debug device.full_path
      logger.debug score
      score_per_device[device] = score
    end
    return score_per_device
  end

  def self.add_condition(condition, started)
    if started
      return "or #{condition} " 
    else
      return "#{condition} "
    end
  end

  def create_temp_combination
    mac_vendor_name = mac_vendor ? mac_vendor.name : ''
    oui = mac_vendor ? mac_vendor.mac : nil
    temp_combination = TempCombination.create!(:dhcp_fingerprint => dhcp_fingerprint.value, :dhcp6_fingerprint => dhcp6_fingerprint.value, :dhcp6_enterprise => dhcp6_enterprise.value, :user_agent => user_agent.value, :dhcp_vendor => dhcp_vendor.value, :mac_vendor => mac_vendor_name, :oui => oui)

    if Rails.application.config.active_job.queue_adapter != :inline
      DeleteTempCombinationJob.set(wait: 2.minute).perform_later(temp_combination)
    end

    return temp_combination
  end

end

