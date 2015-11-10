require 'iconv'

namespace :import do |ns|
  task :list do
    puts 'All tasks:'
    puts ns.tasks
  end

  task :android_models, [:file_path] => [:environment] do |t, args|
    discovered_manufacturers = []
    discovered_devices = []
    discovered_models = []
    ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
    if args[:file_path].nil?
      puts "No file specified. Exiting"
      next
    end
  
    line_num=0
    text=File.open(args[:file_path]).read
    text.gsub!(/\r\n?/, "\n")
    generic_android = Device.where(:name => "Generic Android").first
    count = 0
    text.each_line do |line|
      line.gsub!(/\n/, "")
      line.gsub!(/^ */, "")
      data = line.split(/[ ]{2,}/)
      next if data.size != 4
      count += 1
      manufacturer = data[0]
      name = data[1]
      name = ic.iconv(name + ' ')[0..-2]
      name.gsub!(/ *$/, "")
      name.gsub!(/\\/, "")
      model_info = data[3]
      puts "'#{manufacturer}' '#{name}' '#{model_info}'"
      Rails.logger.debug "got device name : '#{name}'"

      manufacturer_device = Device.where('lower(name) = ?', "#{manufacturer} Android".downcase).first
      if manufacturer_device.nil?
        manufacturer_device = Device.create!(:name => "#{manufacturer} Android", :parent => generic_android)
        Rails.logger.info "Created manufacturer #{manufacturer_device.name}"
        discovered_manufacturers << manufacturer_device
      end
      manufacturer = manufacturer_device

      device = Device.where('lower(name) = ?', name.downcase).first
      if device.nil?
        Rails.logger.warn "Device #{name} doesn't exist yet. Creating it"
        device = Device.create!(:name => name, :parent => manufacturer)
        discovered_devices << device
      else
        Rails.logger.debug "Device #{name} exists"
      end

      model_number = model_info.gsub('\'', '\'\'') 
      model_number = model_number.gsub('\\', "") 
      model_number = model_number.gsub("(", "\\(") 
      model_number = model_number.gsub(")", "\\)") 
      model_number = ic.iconv(model_number + ' ')[0..-2]
      discoverer = Discoverer.where(:device => device).where("lower(description) = ?", "#{name} from model # on User Agent".downcase).first
      rule_value = "user_agents.value regexp '#{model_number}[\);/ ]{1}' and user_agents.value not regexp '[A-Za-z0-9]#{model_number}'"
      unless discoverer.nil?
        rule_already_in = false
        discoverer.device_rules.each do |rule|
          if rule.value == rule_value
            rule_already_in = true
            break
          end
        end

        unless rule_already_in
          Rails.logger.warn "Adding rule for model # #{model_number} to device #{device.name}"
          rule = Rule.create!(:value => rule_value, :device_discoverer => discoverer)
          discovered_models << model_number
        end
      else
        discoverer = Discoverer.create!(:description => "#{name} from model # on User Agent", :priority => 5, :device => device)
        Rails.logger.warn "Adding rule for model # #{model_number} to device #{device.name}"
        rule = Rule.create!(:value => rule_value, :device_discoverer => discoverer)
        discovered_models << model_number
      end

    end

    Event.create(:title => "Android phones processing : Created #{discovered_manufacturers.size} manufacturers, #{discovered_devices.size} devices and #{discovered_models.size} models")    

  end

  task :discover_windows_phone => :environment do
    discovered_manufacturers = []
    discovered_devices = []
    windows_phone = Device.where(:name => "Windows Phone").first
    UserAgent.all.each do |user_agent|
      value = user_agent.value.nil? ? '' : user_agent.value
      matchdata = value.match(/.*Windows Phone.*;[ ]{0,1}([A-Za-z0-9 ]+);[ ]{0,1}([A-Za-z0-9 ]+)[);]{1}.*/)
      unless matchdata.nil?
        model = matchdata[2]
        manufacturer_name = matchdata[1]
        Rails.logger.debug "Processing : #{manufacturer_name} #{model}"
        Rails.logger.debug "Current user agent : #{user_agent.value}"

        manufacturer = Device.where('lower(name) = ?',  "#{manufacturer_name} Windows Phone".downcase).first
        if manufacturer.nil?
          Rails.logger.warn "Manufacturer #{manufacturer_name} Windows Phone doesn't exists"
          manufacturer = Device.create!(:name => "#{manufacturer_name} Windows Phone", :parent => windows_phone)
          Rails.logger.info "Created manufacturer #{manufacturer.name}"
          discovered_manufacturers << manufacturer
        end

        Rails.logger.debug "Discoverered #{model}"
        device = Device.where("lower(name) = ?", "Windows phone - #{model.downcase}".downcase).first
        if device.nil?
          device = Device.create!(:name => "Windows phone - #{model}", :parent => manufacturer)
          Rails.logger.warn "Created device #{model}"
          discovered_devices << device
        else
          Rails.logger.debug "Device #{model} exists"
        end

        rule_value = "user_agents.value regexp '.*Windows Phone.*;[ ]{0,1}#{manufacturer_name};[ ]{0,1}#{model}[);].*'"

        discoverer = Discoverer.where(:device => device).where("lower(description) = ?", "Windows phone - #{model} from model # on User Agent".downcase).first
        unless discoverer.nil?
          rule_already_in = false
          discoverer.device_rules.each do |rule|
            if rule.value == rule_value 
              rule_already_in = true
              break
            end
          end

          unless rule_already_in
            Rails.logger.warn "Adding rule for model # #{model} to device #{device.name}"
            rule = Rule.create!(:value => rule_value, :device_discoverer => discoverer)
          end
        else
          discoverer = Discoverer.create!(:description => "Windows phone - #{model} from model # on User Agent", :priority => 5, :device => device)
          Rails.logger.warn "Adding rule for model # #{model} to device #{device.name}"
          rule = Rule.create!(:value => rule_value, :device_discoverer => discoverer)
        end


      end




    end

    Event.create(:title => "Windows phones processing : Created #{discovered_manufacturers.size} manufacturers and #{discovered_devices.size} devices")    

  end


  task :discover_blackberry_models => :environment do
    blackberry = Device.where(:name => "RIM BlackBerry").first
    discovered_devices = []
    UserAgent.all.each do |user_agent|
      value = user_agent.value.nil? ? '' : user_agent.value
      matchdata = value.match(/(BlackBerry[; ]{0,1}[0-9]+)/)
      model = matchdata.nil? ? nil : matchdata[0]
      if model
        model = model.gsub(/^ /, '')
        model_untouched = model
        model = model.gsub(';', ' ')

        # insert a space between BlackBerry + model if there's none
        model = model.insert(10, ' ') if model[10] != ' '

        Rails.logger.info "Discoverered #{model}"
        device = Device.where("lower(name) = ?", model.downcase).first
        if device.nil?
          device = Device.create!(:name => model, :parent => blackberry)
          Rails.logger.warn "Created device #{model}"
          discovered_devices << device
        else
          Rails.logger.debug "Device #{model} exists"
        end

        discoverer = Discoverer.where(:device => device).where("lower(description) = ?", "#{model} from model # on User Agent".downcase).first
        unless discoverer.nil?
          rule_already_in = false
          discoverer.device_rules.each do |rule|
            if rule.value == "user_agents.value LIKE '%#{model_untouched}%'"
              rule_already_in = true
              break
            end
          end

          unless rule_already_in
            Rails.logger.warn "Adding rule for model # #{model_untouched} to device #{device.name}"
            rule = Rule.create!(:value => "user_agents.value LIKE '%#{model_untouched}%'", :device_discoverer => discoverer)
          end
        else
          discoverer = Discoverer.create!(:description => "#{model} from model # on User Agent", :priority => 5, :device => device)
          Rails.logger.warn "Adding rule for model # #{model_untouched} to device #{device.name}"
          rule = Rule.create!(:value => "user_agents.value LIKE '%#{model_untouched}%'", :device_discoverer => discoverer)
        end
      end
    end


    Event.create(:title => "Blackberry phones processing : Created #{discovered_devices.size} devices")    

  end


  task :merge_stats, [:db_path, :days_to_merge] => [:environment] do |t, args|

    discovered_combinations = []

    # what is the last inserted that has no owner (should be by this script)
    last_inserted = Combination.where(:submitter_id => nil).order(created_at: :desc).first
    # the stats database uses the local time at Inverse inc.
    last_inserted_time = Time.now.in_time_zone("Eastern Time (US & Canada)") 
    #puts last_inserted_time

    if args[:db_path].nil?
      puts "No database specified. Exiting"
      next
    end

    if args[:days_to_merge].nil?
      days_to_merge = '365'
      puts "No delay set. Using #{days_to_merge} days"
    else
      days_to_merge = args[:days_to_merge]
    end

    orig = SQLite3::Database.open args[:db_path]

    stm = orig.prepare "select count(*) as total_count from stats_dhcp left outer join stats_http on stats_dhcp.mac=stats_http.mac where stats_dhcp.timestamp > date('now', '-#{days_to_merge} days')"

    result = stm.execute

    total_count = 0
    result.each do |row| total_count = row[0] end

    stm = orig.prepare "select stats_dhcp.mac, stats_dhcp.dhcp_fingerprint, stats_dhcp.vendor_id, stats_http.user_agent from stats_dhcp left outer join stats_http on stats_dhcp.mac=stats_http.mac where stats_dhcp.timestamp > date('now', '-#{days_to_merge} days') "

    result = stm.execute

    count = 0
    result.each do |row|
      ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')

      Rails.logger.debug "Processing #{row[0]} #{count}/#{total_count}"

      mac_value = ic.iconv(row[0] + ' ')[0..-2][0..7]
      dhcp_fingerprint_value = row[1].nil? ? '' : ic.iconv(row[1] + ' ')[0..-2]
      dhcp_vendor_value = row[2].nil? ? '' : ic.iconv(row[2] + ' ')[0..-2]
      user_agent_value = row[3].nil? ? '' : ic.iconv(row[3] + ' ')[0..-2]
      DhcpFingerprint.create(:value => dhcp_fingerprint_value)
      dhcp_fingerprint = DhcpFingerprint.where(:value => dhcp_fingerprint_value).first
      UserAgent.create(:value => user_agent_value)
      user_agent = UserAgent.where(:value => user_agent_value).first
      DhcpVendor.create(:value => dhcp_vendor_value)
      dhcp_vendor = DhcpVendor.where(:value => dhcp_vendor_value).first 

      combination = Combination.new
      combination.dhcp_fingerprint = dhcp_fingerprint
      combination.user_agent = user_agent
      combination.dhcp_vendor = dhcp_vendor
      combination.mac_vendor = MacVendor.from_mac(mac_value)
      success = combination.save
      discovered_combinations << combination if success
      combination = Combination.where(:user_agent => user_agent, :dhcp_fingerprint => dhcp_fingerprint, :dhcp_vendor => dhcp_vendor, :mac_vendor => combination.mac_vendor).first

      count+=1

    end

    puts "Done processing join dhcp -> http"

    stm = orig.prepare "select count(*) as total_count from stats_http left outer join stats_dhcp on stats_dhcp.mac=stats_http.mac where stats_dhcp.timestamp > date('now', '-#{days_to_merge} days')"

    result = stm.execute

    total_count = 0
    result.each do |row| total_count = row[0] end

    stm = orig.prepare "select stats_dhcp.mac, stats_dhcp.dhcp_fingerprint, stats_dhcp.vendor_id, stats_http.user_agent from stats_http left outer join stats_dhcp on stats_dhcp.mac=stats_http.mac where stats_dhcp.timestamp > date('now', '-#{days_to_merge} days') "

    result = stm.execute

    count = 0
    result.each do |row|
      ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')

      Rails.logger.debug "Processing #{row[0]} #{count}/#{total_count}"

      mac_value = row[0].nil? ? '' : ic.iconv(row[0] + ' ')[0..-2][0..7]
      dhcp_fingerprint_value = row[1].nil? ? '' : ic.iconv(row[1] + ' ')[0..-2]
      dhcp_vendor_value = row[2].nil? ? '' : ic.iconv(row[2] + ' ')[0..-2]
      user_agent_value = row[3].nil? ? '' : ic.iconv(row[3] + ' ')[0..-2]
      DhcpFingerprint.create(:value => dhcp_fingerprint_value)
      dhcp_fingerprint = DhcpFingerprint.where(:value => dhcp_fingerprint_value).first
      UserAgent.create(:value => user_agent_value)
      user_agent = UserAgent.where(:value => user_agent_value).first
      DhcpVendor.create(:value => dhcp_vendor_value)
      dhcp_vendor = DhcpVendor.where(:value => dhcp_vendor_value).first 

      combination = Combination.new
      combination.dhcp_fingerprint = dhcp_fingerprint
      combination.user_agent = user_agent
      combination.dhcp_vendor = dhcp_vendor
      combination.mac_vendor = MacVendor.from_mac(mac_value)
      success = combination.save
      discovered_combinations << combination if success
      combination = Combination.where(:user_agent => user_agent, :dhcp_fingerprint => dhcp_fingerprint, :dhcp_vendor => dhcp_vendor, :mac_vendor => combination.mac_vendor).first

      count+=1

    end

    puts "Done processing join http -> dhcp"

    puts "Done with merging stats"


    Event.create(:title => "Merge in stats : Created #{discovered_combinations.size} combinations")    

  end


  task :wipe_android_rules => :environment do
    android = Device.where(:name => "Generic Android").first
    Discoverer.all.each do |d|
      d.delete if d.device.parents.include?(android)
    end
  end

  task :rewrite_android_rules => :environment do 
    android = Device.where(:name => "Generic Android").first
    Rule.all.each do |rule|
      unless rule.device_discoverer && rule.device_discoverer.device
        next
      end
      description_match = rule.device_discoverer.description.match(/from model # on User Agent/)
      device_match = rule.device_discoverer.device.parents.include?(android)
      model = rule.value.match(/\].*\](.*)\'/)
      if description_match && device_match && model.captures[0]
        model_number = model.captures[0]
        puts "found #{rule.id} : #{model_number}"
        new_value = "user_agents.value regexp '#{model[1]}[\);/ ]{1}' and user_agents.value not regexp '[A-Za-z0-9]#{model_number}'"
        puts new_value
        rule.value = new_value
        rule.save!
      end
      #if model
      #  puts model
      #  puts model[1] 
      #  break
      #  new_value = "user_agents.value regexp '#{model[1]}[\);/ ]{1}' and user_agents.value not regexp '[A-Za-z0-9]#{model[1]}'"
      #  rule.value = new_value 
      #  rule.save!
      #end
    end
  end

  task :merge_from_dhcp_email, [:file_path] => [:environment] do |t, args|
    if args[:file_path].nil?
      puts "No file path specified. Exiting"
      next
    end
    text=File.open(args[:file_path]).read
    text.gsub!(/\r\n?/, "\n")
    state = 'searching_fingerprint'

    user_agent_value = nil  
    fingerprint_value = nil

    text.each_line do |line|

      line.gsub!(/\n?/, "")

      data = line.scan(/^User Agent: (.*)/)

      if state == 'searching_fingerprint' && !line.empty?
        #puts "Found value #{line}"
        fingerprint_value = line
        fingerprint_value.gsub!(/^[ ]?/, '')
        fingerprint_value.gsub!(/[ ]?$/, '')
        state = "searching_ua"
      elsif state == 'searching_ua' && !data.empty?
        user_agent_value = data.last.first
        user_agent_value.gsub!(/^[ ]?/, '')
        user_agent_value.gsub!(/[ ]?$/, '')
        #puts "Found fingerprint #{fingerprint}"
        state = 'searching_end'
      elsif state == 'searching_end' && line.empty?
        #puts "Done processing"
        puts "ua : '#{user_agent_value}', fingerprint : '#{fingerprint_value}'"

        Combination.get_or_create(:user_agent => user_agent_value, :dhcp_fingerprint => dhcp_fingerprint_value)

        state = 'searching_ua'
      end
    end
  end

  task :merge_from_ua_email, [:file_path] => [:environment] do |t, args|
    if args[:file_path].nil?
      puts "No file path specified. Exiting"
      next
    end
    text=File.open(args[:file_path]).read
    text.gsub!(/\r\n?/, "\n")
    state = 'searching_ua'

    user_agent_value = nil  
    fingerprint_value = nil

    text.each_line do |line|
      data = line.scan(/^DHCP Fingerprint: (.*)/)

      line.gsub!(/\n?/, "")

      if state == 'searching_ua' && !line.empty?
        #puts "Found value #{line}"
        user_agent_value = line
        user_agent_value.gsub!(/^[ ]?/, '')
        user_agent_value.gsub!(/[ ]?$/, '')
        state = "searching_fingerprint"
      elsif state == 'searching_fingerprint' && !data.empty?
        fingerprint_value = data.last.first
        fingerprint_value.gsub!(/^[ ]?/, '')
        fingerprint_value.gsub!(/[ ]?$/, '')
        #puts "Found fingerprint #{fingerprint}"
        state = 'searching_end'
      elsif state == 'searching_end' && line.empty?
        #puts "Done processing"
        puts "ua : #{user_agent_value}, fingerprint : #{fingerprint_value}"

        Combination.get_or_create(:user_agent => user_agent_value, :dhcp_fingerprint => dhcp_fingerprint_value)

        state = 'searching_ua'
      end
    end
  end

  task :cfnetwork, [:file_path] => [:environment] do |t, args|
    if args[:file_path].nil?
      puts "No file path specified. Exiting"
      next
    end
    require 'nokogiri'
    page = Nokogiri::HTML(open(args[:file_path]))
    table = page.css('table')
    table.css('tr').each do |line|
      cf_network = nil
      model = nil
      version = nil
      got_cf_network = false
      line.css('td').each do |info|
        unless got_cf_network
          cf_network = info.text
          got_cf_network = true
        else
          data = info.text.match(/([a-zA-Z ]+) ([0-9.]+)/)
          if data
            model = data[1]
            version = data[2]
          end
          break
        end
      end
      if cf_network && model
        Rails.logger.debug "cf_network : #{cf_network}"
        Rails.logger.debug "model : #{model}"
        Rails.logger.debug "version : #{version}"

        if model == "Mac OSX"
          device = Device.where(:name => "Mac OS X").first
        elsif model == "iOS"
          device = Device.where(:name => "Apple iPod, iPhone or iPad").first
        else
          next
        end

        description = "#{device.name} from #{cf_network} on user agent"

        discoverer = Discoverer.where(:device => device).where("lower(description) = ?", description.downcase).first
        if discoverer.nil?
          rule_value = "user_agents.value like '%#{cf_network}%'"
          discoverer = Discoverer.create!(:description => description, :priority => 5, :device => device)
          Rails.logger.warn "Adding rule for cf network #{cf_network} to device #{device.name} (#{rule_value})"
          rule = Rule.create!(:value => rule_value, :device_discoverer => discoverer)
        end

        description = "#{device.name} version #{version} from #{cf_network} on user agent"
        discoverer = Discoverer.where(:device => device).where("lower(description) = ?", description.downcase).first
         if discoverer.nil? && version
          rule_value = "user_agents.value like '%#{cf_network}%'"
          discoverer = Discoverer.create!(:description => description, :priority => 5, :device => device, :version => version)
          Rails.logger.warn "Adding rule for cf network #{cf_network} to device #{device.name} (#{rule_value}) with version #{version}"
          rule = Rule.create!(:value => rule_value, :version_discoverer => discoverer)
        end       

      end
    end
  end

  
  task :detect_device_metadata => :environment do
    require "browser"
    mobiles = []
    tablets = []
    orphan_user_agents = []

    whitelisted = []
    whitelisted << Device.where(:name => 'Windows').first.self_and_childs
    whitelisted << Device.where(:name => 'Macintosh').first.self_and_childs
    whitelisted << Device.where(:name => 'Linux').first.self_and_childs
    whitelisted = whitelisted.flatten

    UserAgent.all.each do |user_agent|
      browser = Browser.new(:ua => user_agent.value)
      device = user_agent.combinations.first.device unless user_agent.combinations.first.nil?
      orphan_user_agents << user_agent if user_agent.combinations.first.nil?
      next if device.nil? || whitelisted.include?(device)
      mobiles <<  device if browser.mobile? and !mobiles.include?(device)
      tablets << device if browser.tablet? and !tablets.include?(device)
    end
    puts "Found #{orphan_user_agents.size} orphan user agents"
    puts "Found #{mobiles.size} mobile devices"
    puts "Found #{tablets.size} tablet devices"

    mobiles.each do |device|
      device.update!(:mobile => true)
    end

    tablets.each do |device|
      unless device.mobile?
        device.update!(:tablet => true)
      else
        device.update!(:tablet => false)
      end 
    end

    whitelisted.each do |device|
      device.update(:mobile => false, :tablet => false)
    end

  end

  task :rename_windows_phone_discoverers => :environment do
    windows_phone = Device.find(5474)
    Discoverer.all.each do |discoverer|
      if discoverer.description.match(/from model # on User Agent/)
        if discoverer.device.parents.include? windows_phone
          puts "Will rename #{discoverer.description}"
          discoverer.description = "Windows phone - #{discoverer.description}"
          puts discoverer.description
          discoverer.save
        end 
      end
    end 
  end

  task :rename_windows_phones => :environment do 
    windows_phone = Device.find(5474)
    windows_phone.childs.flatten.each do |device|
      unless device.name.match /Windows phone/i
        device.name = "Windows phone - #{device.name}"
        device.save!
      end
    end
  end

  task :mac_vendors_from_oui_file, [:file_path] => [:environment] do |t, args|
    unless args[:file_path] && File.exists?(args[:file_path])
      puts "Missing file path or file doesn't exist..."
      next
    end

    created = []
    line_num=0
    text=File.open(args[:file_path]).read
    text.gsub!(/\r\n?/, "\n")
    text.each_line do |line|
      line.gsub!(/\n/, "")
      if line =~ /.*\(hex\).*/
        info = line.match(/(?<mac>.{8}).*\(hex\)\s+(?<name>.*)/)
        mac = info['mac'].gsub!(/-/, '').downcase
        name = info['name']
        puts mac+", "+name
        unless MacVendor.where(:mac => mac).first
          mac_vendor = MacVendor.create!(:name => name, :mac => mac)
          created << mac_vendor
        end
      end
    end
    Event.create(:title => "MAC vendor processing : Created #{created.size} new MAC vendors")    
  end

end
