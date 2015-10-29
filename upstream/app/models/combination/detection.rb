

class Combination < FingerbankModel
  def process(options = {:with_version => false, :save => true})
    if self.fixed
      logger.info "Not processing combination #{self.id} as it is set to be fixed"
      return
    end


    discoverer_detected_device = nil
    new_score = nil

    discoverers_match = find_matching_discoverers

    unless discoverers_match.empty?
      deepest = 0
      discoverers = discoverers_match 
      scores = Combination.score_from_discoverers discoverers
      discoverer_detected_device, new_score = (scores.sort_by {|key, value| value}).last
      self.device = discoverer_detected_device 
      self.score = new_score unless new_score.nil?
    else
      logger.warn "empty device rules for #{id}"
    end 

    if options[:with_version]
      if discoverer_detected_device.nil?
        # no choice really
        # leave as is 
        logger.warn "Couldn't find device for combination #{id} so can't find version"
      else
        save!
        find_version
        logger.debug self.device.nil? ? "Unknown device" : "Detected device "+self.device.full_path  
        logger.debug "Score "+score.to_s
        logger.info version ? "Version "+version : "Unknown version"
      end
    end
    save! if options[:save]
  end


  def matches_discoverer?(discoverer)
    matches = []
    discoverer.device_rules.each do |rule|
      computed = rule.computed
      sql = "SELECT combinations.id from combinations 
              inner join user_agents on user_agents.id=combinations.user_agent_id 
              inner join dhcp_fingerprints on dhcp_fingerprints.id=combinations.dhcp_fingerprint_id
              inner join dhcp6_fingerprints on dhcp6_fingerprints.id=combinations.dhcp6_fingerprint_id
              inner join dhcp6_enterprises on dhcp6_enterprises.id=combinations.dhcp6_enterprise_id
              inner join dhcp_vendors on dhcp_vendors.id=combinations.dhcp_vendor_id
              left join mac_vendors on mac_vendors.id=combinations.mac_vendor_id
              WHERE (combinations.id=#{id}) AND #{computed};"
      records = ActiveRecord::Base.connection.execute(sql)
      unless records.size == 0
        matches.push rule
        logger.debug "Matched OS rule in #{discoverer.id}"
      end
    end

    discoverer.version_rules.each do |rule|
      computed = rule.computed
      sql = "SELECT combinations.id from combinations 
              inner join user_agents on user_agents.id=combinations.user_agent_id 
              inner join dhcp_fingerprints on dhcp_fingerprints.id=combinations.dhcp_fingerprint_id
              inner join dhcp6_fingerprints on dhcp6_fingerprints.id=combinations.dhcp6_fingerprint_id
              inner join dhcp6_enterprises on dhcp6_enterprises.id=combinations.dhcp6_enterprise_id
              inner join dhcp_vendors on dhcp_vendors.id=combinations.dhcp_vendor_id
              left join mac_vendors on mac_vendors.id=combinations.mac_vendor_id
              WHERE (combinations.id=#{id}) AND #{computed};"
      records = ActiveRecord::Base.connection.execute(sql)
      unless records.size == 0
        matches.push rule
        logger.debug "Matched OS rule in #{discoverer.id}"
      end
    end

    return !matches.empty?

  end

  def find_matching_discoverers
    discoverers_match = find_matching_discoverers_cache
    unless discoverers_match.nil?
      logger.debug "Cache hit in device_matching_discoverers for combination #{id}"
      self.processed_method = "find_matching_discoverers_cache"
      return discoverers_match
    end

    discoverers_match = find_matching_discoverers_local
    unless discoverers_match.nil?
      logger.debug "Cache hit in local for combination #{id}"
      self.processed_method = "find_matching_discoverers_local"
      return discoverers_match
    end

    discoverers_match = find_matching_discoverers_tmp_table
    unless discoverers_match.nil?
      logger.debug "Cache hit in ifs_for_discoverer for combination #{id}"
      self.processed_method = "find_matching_discoverers_tmp_table"
      return discoverers_match
    end

    # Notify full cache miss to discoverer
    Discoverer.full_cache_miss
    
    # useless to do in production as it will jam the system
    unless Rails.env.production?
      discoverers_match = find_matching_discoverers_long
      logger.warn "Computing discoverers data without cache. THIS WILL BE LONG !!!!"
      self.processed_method = "find_matching_discoverers_long"
    end

    return discoverers_match
  end

  def find_matching_discoverers_cache
    return Discoverer.device_matching_discoverers[id]
  end

  def find_matching_discoverers_local
    model_regex_assoc = Discoverer.model_regex_assoc
    return if model_regex_assoc.nil?
    assoc = model_regex_assoc[:regex_assoc]
    non_regex_discoverers = model_regex_assoc[:non_regex_discoverers]


    ua = user_agent.value
    discoverers = []
    temp_combination = self.create_temp_combination
    assoc.each do |regex, discoverer|
      if ua =~ /#{regex}/ && temp_combination.matches?(discoverer)
         discoverers << discoverer
      end
    end

    other_discoverers = temp_combination.matches_on_ifs?(model_regex_assoc[:non_regex_discoverers_ifs][0],model_regex_assoc[:non_regex_discoverers_ifs][1] )
    discoverers << other_discoverers unless other_discoverers.empty?

    discoverers = discoverers.flatten

    return discoverers
  end

  def find_matching_discoverers_tmp_table
    valid_discoverers = []
    ifs, conditions = Discoverer.discoverers_ifs
    matches = []

    temp_combination = self.create_temp_combination
    unless ifs.empty?
      return temp_combination.matches_on_ifs?(ifs, conditions)   
      self.processed_method = "find_matching_discoverers_tmp_table"
    else
      return nil
    end

  end

  def find_matching_discoverers_long
    discoverers = Discoverer.all
    discoverers_matched = []
    
    temp_combination = self.create_temp_combination
    discoverers.each do |discoverer|
      if temp_combination.matches?(discoverer)
        discoverers_matched << discoverer
      end
    end
    return discoverers_matched
  end

  def find_version
    if self.device.nil?
      logger.warn "device is nil"
      return
    end
    version_discoverers_ifs = Discoverer.version_discoverers_ifs
    if version_discoverers_ifs.nil?
      # Notify full cache miss to discoverer
      Discoverer.full_cache_miss
      return
    end

    temp_combination = self.create_temp_combination
    valid_discoverers = temp_combination.matches_on_ifs?(version_discoverers_ifs[:ifs], version_discoverers_ifs[:conditions])
    versions_discovered = {} 
    valid_discoverers.each do |discoverer|
      version_discovered = find_version_from_discoverer(discoverer)
      versions_discovered[discoverer.id] = version_discovered 
    end
    version_discoverer = valid_discoverers.sort{|a,b| a.priority <=> b.priority}.last
    self.version = versions_discovered[version_discoverer.id] unless version_discoverer.nil?
  end


  def find_version_from_discoverer(discoverer)
    sql = "SELECT #{discoverer.version_finder} from combinations 
            inner join user_agents on user_agents.id=combinations.user_agent_id 
            inner join dhcp_fingerprints on dhcp_fingerprints.id=combinations.dhcp_fingerprint_id
            inner join dhcp6_fingerprints on dhcp6_fingerprints.id=combinations.dhcp6_fingerprint_id
            inner join dhcp6_enterprises on dhcp6_enterprises.id=combinations.dhcp6_enterprise_id
            inner join dhcp_vendors on dhcp_vendors.id=combinations.dhcp_vendor_id
            left join mac_vendors on mac_vendors.id=combinations.mac_vendor_id
            WHERE (combinations.id=#{id});"
    records = ActiveRecord::Base.connection.execute(sql)
    record = records.first
    return record ? record[0] : nil
  end

end
