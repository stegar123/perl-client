class User < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :email
  validates_uniqueness_of :name
  validates_uniqueness_of :github_uid, :allow_nil => true, :allow_blank => true
  validates_uniqueness_of :display_name, :allow_nil => true, :allow_blank => true

  has_many :combinations, :foreign_key => "submitter_id"
  has_many :watched_combinations
  has_many :devices, :foreign_key => "submitter_id"

  scope :admins, -> {where(:level => 10)}
  scope :unlimited, -> {where(:level => 9)}
  scope :api_submitters, -> {where(:level => 5)}
  scope :community, -> {where(:level => 0)}

  after_create :generate_key

  def self.MAX_TIMEFRAMED_REQUESTS
     return ENV['MAX_TIMEFRAMED_REQUESTS'].to_i || 10000
  end

  def self.LEVELS
    return {
      :community => 0,
      :api_submitter => 5,
      :unlimited => 9,
      :admin => 10,
    }
  end

  def generate_key
    require 'digest/sha1'
    self.key = Digest::SHA1.hexdigest "API-#{Time.now}-#{name}"
    self.save
  end

  def add_request
    self.increment!(:requests)
    self.increment!(:timeframed_requests)
  end

  def can_use_api
    # admins have the right to submit whatever happens
    if self.admin?
      return true
    end

    # normal users have a limit and can't be blocked
    if !reached_api_limit && !self.blocked 
      return true
    end
    return false
  end

  def reached_api_limit
    request_number = self.timeframed_requests || 0

    if self.unlimited?
      return false
    end

    # normal users have a limit and can't be blocked
    if request_number > User.MAX_TIMEFRAMED_REQUESTS 
      return true
    end
    return false
  end

  def self.from_omniauth(auth)
    user = self.where(:github_uid => auth.uid).first
    if user 
      user.update!(:github_uid => auth.uid, :name => auth.info.nickname, :display_name => auth.info.name, :email => auth.info.email)
    else
      create(:github_uid => auth.uid, :name => auth.info.nickname, :display_name => auth.info.name, :email => auth.info.email)
    end
    return self.where(:github_uid => auth.uid).first 
  end

  def promote_admin
    promote_to User.LEVELS[:admin]
  end

  def promote_unlimited
    promote_to User.LEVELS[:unlimited]
  end

  def promote_submitter
    promote_to User.LEVELS[:api_submitter]
  end

  def promote_to(level)
    update(:level => level)
  end

  def demote_to(level)
    # we make sure there will be at least an admin left
    unless self.level == User.LEVELS[:admin] && User.admins.size <= 1
      update(:level => level)
    else
      return false 
    end
  end

  def demote
    demote_to(0)
  end

  def admin?
    level >= 10
  end

  def unlimited?
    level >= 9
  end

  def api_submitter?
    level >= 5
  end 

end
