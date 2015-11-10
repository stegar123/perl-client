class Package

  attr_accessor :path
  attr_accessor :db_stats

  def pre_package
    self.db_stats = {}
    self.db_stats[:combinations] = Combination.count
    self.db_stats[:user_agents] = UserAgent.count
    self.db_stats[:dhcp_vendors] = DhcpVendor.count
    self.db_stats[:dhcp_fingerprints] = DhcpFingerprint.count
    self.db_stats[:dhcp6_fingerprints] = Dhcp6Fingerprint.count
    self.db_stats[:dhcp6_enterprises] = Dhcp6Enterprise.count
    self.db_stats[:mac_vendors] = MacVendor.count
  end

  def build_and_release
    self.pre_package
    begin
      self.build
      if self.validate
        self.release
        Event.create(:title => "Fingerbank database released !", :value => "
          Has #{self.db_stats[:combinations]} combinations in it
          Has #{self.db_stats[:user_agents]} user agents in it
          Has #{self.db_stats[:dhcp_fingerprints]} DHCP fingerprints in it
          Has #{self.db_stats[:dhcp6_fingerprints]} DHCPv6 fingerprints in it
          Has #{self.db_stats[:dhcp6_enterprises]} DHCPv6 enterprises in it
          Has #{self.db_stats[:mac_vendors]} MAC vendors in it
        ")
      else
        AdminMailer.package_failed.deliver_later
      end 
    rescue Exception => e
      Rails.logger.error e
      AdminMailer.package_failed.deliver_later
    end

  end

  def build 
    config   = Rails.configuration.database_configuration
    host     = config[Rails.env]["host"]
    database = config[Rails.env]["database"]
    username = config[Rails.env]["username"]
    password = config[Rails.env]["password"]

    sqlite_sql = `sh #{Rails.root.join('db', 'mysql2sqlite.sh')} #{host} #{username} #{password} #{database} "combinations dhcp_vendors user_agents dhcp_fingerprints dhcp6_fingerprints dhcp6_enterprises mac_vendors devices"` 
    dump_fname = Rails.root.join('tmp', "#{Time.now.to_i}.sqlite3dump.sql")
    bak_dump_fname = Rails.root.join('tmp', "#{Time.now.to_i}.sqlite3dump.sql.bak")
    sqlite_sql_output = File.open(dump_fname, 'w') 
    sqlite_sql_output << sqlite_sql
    sqlite_sql_output.close

    # rename the tables to put them singular
    success = system ('sed -i.bak s/\"devices\"/\"device\"/g '+dump_fname.to_s)
    success = system ('sed -i.bak s/\"combinations\"/\"combination\"/g '+dump_fname.to_s)
    success = system ('sed -i.bak s/\"dhcp_fingerprints\"/\"dhcp_fingerprint\"/g '+dump_fname.to_s)
    success = system ('sed -i.bak s/\"dhcp6_fingerprints\"/\"dhcp6_fingerprint\"/g '+dump_fname.to_s)
    success = system ('sed -i.bak s/\"dhcp6_enterprises\"/\"dhcp6_enterprise\"/g '+dump_fname.to_s)
    success = system ('sed -i.bak s/\"user_agents\"/\"user_agent\"/g '+dump_fname.to_s)
    success = system ('sed -i.bak s/\"mac_vendors\"/\"mac_vendor\"/g '+dump_fname.to_s)
    success = system ('sed -i.bak s/\"dhcp_vendors\"/\"dhcp_vendor\"/g '+dump_fname.to_s)

    # replace quote escaping for sqlite3
    success = system ("sed -i.bak \"s/\\\\\\\\'/''/g\" "+dump_fname.to_s)

    db_fname = Rails.root.join('db', 'package', "#{Time.now.to_i}.sqlite3")
    success = system ("sqlite3 #{db_fname} < #{dump_fname}")

    self.path = db_fname

    # delete dump files
    File.delete(dump_fname)
    File.delete(bak_dump_fname)

  end

  def validate

    package_stats = {}
    
    puts self.path.to_s
    packaged = SQLite3::Database.open self.path.to_s

    result = packaged.execute("select count(*) from combination") 
    package_stats[:combinations] = result[0][0]

    result = packaged.execute("select count(*) from user_agent") 
    package_stats[:user_agents] = result[0][0]

    result = packaged.execute("select count(*) from dhcp_vendor") 
    package_stats[:dhcp_vendors] = result[0][0]

    result = packaged.execute("select count(*) from dhcp_fingerprint") 
    package_stats[:dhcp_fingerprints] = result[0][0]

    result = packaged.execute("select count(*) from dhcp6_fingerprint") 
    package_stats[:dhcp6_fingerprints] = result[0][0]

    result = packaged.execute("select count(*) from dhcp6_enterprise") 
    package_stats[:dhcp6_enterprises] = result[0][0]

    result = packaged.execute("select count(*) from mac_vendor") 
    package_stats[:mac_vendors] = result[0][0]

    puts package_stats.inspect

    self.db_stats.each do |table, count|
      unless package_stats[table] >= count
        Rails.logger.error "Table #{table} doesn't have enough rows in the package."
        return false
      end
    end

  end

  def release
    FileUtils.cp self.path, Rails.root.join('db', 'package', "packaged.sqlite3")
  end


end
