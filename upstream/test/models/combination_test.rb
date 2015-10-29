require 'test_helper'

class CombinationTest < ActiveSupport::TestCase

  test 'create a combination with default values' do
    combination = Combination.get_or_create(:dhcp_fingerprint => "1,2,3,4,5", :user_agent => "Mozilla/Dinde")
    assert combination.dhcp_fingerprint.value == "1,2,3,4,5", "DHCP fingerprint was properly created"
    assert combination.user_agent.value == "Mozilla/Dinde", "User agent was properly created"
    assert combination.dhcp_vendor == dhcp_vendors(:empty), "DHCP vendor is set to empty"
    assert combination.mac_vendor.nil?, "MAC vendor is set to NULL"
    assert combination.dhcp6_fingerprint == dhcp6_fingerprints(:empty), "DHCP6 fingerprint vendor is set to empty"

    combination = Combination.get_or_create(:mac => '1234567890ab', :dhcp6_fingerprint => '5,4,3,2,1', :dhcp_vendor => 'Microhard')
    assert combination.mac_vendor == mac_vendors(:zammit), "MAC vendor is properly detected"
    assert combination.dhcp6_fingerprint.value == "5,4,3,2,1", "DHCP6 fingerprint was properly created"
    assert combination.dhcp_vendor.value == 'Microhard', "DHCP vendor was properly created"
  end


  test 'fixtures are there' do
    assert combinations(:iphone).user_agent.value == 'Mozilla/5.0 (iPhone; CPU iPhone OS 7_1_2 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) GSA/5.2.43972 Mobile/11D257 Safari/9537.53'
  end

  test 'combination lookup without cache' do
    # Clear any previous mails
    ActionMailer::Base.deliveries = []

    Rails.cache.clear
    FingerbankCache.clear
    combination = combinations(:iphone)
    assert combination.process(:with_version => true, :save => true), "iPhone combination can be processed"
    assert combination.processed_method == 'find_matching_discoverers_long'
    assert combination.device.name == 'iPhone', "iPhone combination yields the right result"

    FingerbankCache.clear
    combination = combinations(:android)
    assert combination.process(:with_version => true, :save => true), "Android combination can be processed"
    assert combination.processed_method == 'find_matching_discoverers_long'
    assert combination.device.name == 'Nexus zammit', "Android combination yields the right result"

    FingerbankCache.clear
    combination = combinations(:nintendo)
    assert combination.process(:with_version => true, :save => true), "Nintendo combination can be processed"
    assert combination.processed_method == 'find_matching_discoverers_long'
    assert combination.device.name == 'Nintendo Pii', "Nintendo combination yields the right result"

    # We're supposed to send e-mails when having full cache miss
    assert ActionMailer::Base.deliveries.size == 3
  end

  test 'combination lookup with cache discoverers cache' do
    FingerbankCache.clear
    assert Discoverer.device_matching_discoverers.keys.empty?, "Discoverers cache is empty when cache is emptied"
    Discoverer.fbcache
    assert !Discoverer.device_matching_discoverers.keys.empty?, "Discoverers cache is filled up after the build"
    combination = combinations(:iphone)
    assert Discoverer.device_matching_discoverers[combination.id], "Valid known combination will yield in discoverers cache"
    assert !Discoverer.device_matching_discoverers['zammit'], "Invalid id will not yield in discoverers cache"
    assert combination.process(:with_version => true, :save => true), "iPhone combination can be processed"
    assert combination.processed_method == 'find_matching_discoverers_cache'
  end

  test 'combination lookup methods all give the same result' do
    FingerbankCache.clear
    Discoverer.fbcache
    combination = combinations(:iphone)
    through_cache = combination.find_matching_discoverers_cache
    through_local = combination.find_matching_discoverers_local
    through_tmp_table = combination.find_matching_discoverers_tmp_table
    through_long = combination.find_matching_discoverers_long
    
    assert (through_cache == through_tmp_table)
    assert (through_cache == through_local)
    assert (through_cache == through_long)
  end

  test 'combination lookup with discoverers ifs' do
    Discoverer.fbcache
    # we delete the regexes so we go to the ifs
    FingerbankCache.delete("model_regex_assoc")
    # we create a new combination with a new user agent
    user_agent = 'Mozilla/5.0 (Linux; Android 4.1.2; SGH-T599N Build/JZO54K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.86 Mobile Safari/537.36'
    combination = Combination.get_or_create(:user_agent => user_agent)
    assert combination.process(:with_version => true, :save => true), "New android combination can be processed"
    assert combination.processed_method == "find_matching_discoverers_tmp_table"

    mac_vendor = mac_vendors(:nintendo)
    combination = Combination.get_or_create(:user_agent => user_agent, :mac_vendor => mac_vendor)
    assert combination.process(:with_version => true, :save => true), "New android combination can be processed"
    assert combination.processed_method == "find_matching_discoverers_tmp_table"
    
  end

  test 'combination lookup with ruby regex' do
    Discoverer.fbcache
    # we create a new combination with a new user agent
    user_agent = UserAgent.create!(:value => 'Mozilla/5.0 (Linux; Android 4.1.2; SGH-T599N Build/JZO54K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.86 Mobile Safari/537.36')
    combination = Combination.get_or_create(:user_agent => user_agent, :dhcp_vendor => dhcp_vendors(:empty), :dhcp_fingerprint => dhcp_fingerprints(:empty))
    assert combination.process(:with_version => true, :save => true), "New android combination can be processed"
    assert combination.processed_method == "find_matching_discoverers_local"
    
  end



  test 'combination lookup with version' do
    combination = combinations(:iphone)
    Discoverer.fbcache
    combination.process(:with_version => true, :save => true)
    assert combination.version == '7.1.2', "version has been detected properly (#{combination.version})"     
  end

  test 'combination lookup with dhcpv6 fingerprint' do
    combination = combinations(:windows_ipv6)
    Discoverer.fbcache
    combination.process(:with_version => true, :save => true)
    assert combination.device == devices(:windows), "Device with DHCPv6 fingerprint is properly detected through the cache"

    # test it with temp table
    # we create a new combination with a new user agent
    FingerbankCache.delete("model_regex_assoc")

    user_agent = 'Microsaft OS'
    combination = Combination.get_or_create(:user_agent => user_agent, :dhcp6_fingerprint => dhcp6_fingerprints(:microsoft).value)
    assert combination.process(:with_version => true, :save => true), "New windows IPv6 combination can be processed"
    assert combination.processed_method == "find_matching_discoverers_tmp_table"   
    assert combination.device == devices(:windows), "Windows IPv6 combination yields the right result through the temp table"

    # test it full
    FingerbankCache.clear
    combination = combinations(:windows_ipv6)
    assert combination.process(:with_version => true, :save => true), "Windows IPv6 combination can be processed"
    assert combination.processed_method == 'find_matching_discoverers_long'
    assert combination.device == devices(:windows), "Windows IPv6 combination yields the right result through a full scan"
   
  end

  test 'combination lookup with dhcpv6 enterprise' do
    combination = combinations(:android_ipv6)
    Discoverer.fbcache
    combination.process(:with_version => true, :save => true)
    assert combination.device == devices(:android), "Device with DHCPv6 fingerprint is properly detected through the cache"

    # test it with temp table
    # we create a new combination with a new user agent
    FingerbankCache.delete("model_regex_assoc")

    user_agent = 'Gaggle OS'
    combination = Combination.get_or_create(:user_agent => user_agent, :dhcp6_enterprise => dhcp6_enterprises(:android).value)
    assert combination.process(:with_version => true, :save => true), "New Android IPv6 combination can be processed"
    assert combination.processed_method == "find_matching_discoverers_tmp_table"   
    assert combination.device == devices(:android), "Android IPv6 combination yields the right result through the temp table"

    # test it full
    FingerbankCache.clear
    combination = combinations(:android_ipv6)
    assert combination.process(:with_version => true, :save => true), "Android IPv6 combination can be processed"
    assert combination.processed_method == 'find_matching_discoverers_long'
    assert combination.device == devices(:android), "Android IPv6 combination yields the right result through a full scan"
   
  end

  test 'combination lookup with OUI' do
    Discoverer.fbcache
    FingerbankCache.delete("model_regex_assoc")
    
    combination = Combination.get_or_create(:user_agent => "test oui", :mac => "23:45:67:89:90:12");
    assert combination.process(:with_version => true, :save => true), "New combination can be detected properly with OUI rule"
    assert combination.processed_method == "find_matching_discoverers_tmp_table"   
    assert combination.device == devices(:nintendo), "Combination discovered by OUI yields the right result through the temp table"

  end

  test 'cant process a fixed combination' do
    combination = Combination.get_or_create(:user_agent => 'iphone', :mac => "12:34:56:78:90:ab")
    assert combination.process(:with_version => true, :save => true), "Can process the test fixed combination with fixed flag off"
    assert combination.device == devices(:iphone), "Test fixed combination gives proper result"
    combination.fixed = true
    combination.device = devices(:android)
    combination.save
    combination.process(:with_version => true, :save => true)
    assert combination.device == devices(:android), "Processing a fixed combination doesn't change it's device"
  end

end
