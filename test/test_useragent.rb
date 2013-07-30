require 'test/unit'
require 'useragent'

@@tests = YAML.load_file(File.expand_path(File.dirname(__FILE__)+"/test_useragent.yml"))
UserAgent.load_file(File.expand_path(File.dirname(__FILE__)+'/../data/useragent.yml'))

class UseragentTest < Test::Unit::TestCase
  def test_browser_identification
    @@tests['browser']['parse'].each do |key,uas|
      uas.each do |ua|
        browser = UserAgent::Browser.find(ua)
        assert_equal key, browser.key
      end
    end
  end

  def test_browser_version_parsing
    @@tests['browser']['version'].each do |ua|
      browser = UserAgent::Browser.find(ua['user_agent'])
      assert_equal ua['version'], browser.version(ua['user_agent'])
    end
  end

  def test_operating_system_device_type_identification
    @@tests['operating_system']['device_type'].each do |device_type,uas|
      uas.each do |ua|
        os = UserAgent::OperatingSystem.find(ua)
        assert_equal os.device_type, device_type.to_sym
      end
    end
  end

  def test_operating_system_identification
    @@tests['operating_system']['parse'].each do |operating_system,uas|
      uas.each do |ua|
        os = UserAgent::OperatingSystem.find(ua)
        assert_equal os.key, operating_system
      end
    end
  end

  def test_user_agent_identification
    @@tests['browser']['version'].each do |ua|
      user_agent = UserAgent.find(ua['user_agent'])
      assert_equal ua['version'], user_agent.browser_version
    end
  end
end
