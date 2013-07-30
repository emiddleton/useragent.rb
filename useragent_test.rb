require './useragent'

tests = YAML.load_file("./useragent_test.yml")
ua = YAML.load_file('./useragent.yml')

UserAgent::Browser.load(ua)

tests['browser']['parse'].each do |name,uas|
  uas.each do |ua|
    b = UserAgent::Browser.find(ua)
    unless b.key == name
      puts b.inspect
      raise "#{name} failed\n#{ua}\n\n"
    end
  end
end
puts "parsing passed"

tests['browser']['version'].each do |ua|
  b = UserAgent::Browser.find(ua['user_agent'])
  unless ua['version'] == b.version(ua['user_agent'])
    puts "exected #{ua['version'].inspect} -> #{b.version(ua['user_agent']).inspect}"
    raise "#{ua['user_agent']} failed\n"
  end
end
puts "versions passed"

UserAgent::OperatingSystem.load(ua)

tests['operating_system']['device_type'].each do |device_type,uas|
  uas.each do |ua|
    os = UserAgent::OperatingSystem.find(ua)
    unless os.device_type == device_type.to_sym
      puts os.inspect
      puts "#{device_type} -> #{os.device_type}"
      raise "#{device_type}[#{ua}] failed"
    end
  end
end
puts "device_type passed"

tests['operating_system']['parse'].each do |operating_system,uas|
#  puts "test \"#{operating_system}"
  uas.each do |ua|
    os = UserAgent::OperatingSystem.find(ua)
#    puts "* \"#{ua}\""
    unless os.key == operating_system
      puts os.inspect
      puts "#{operating_system} -> #{os.key}"
      raise "#{operating_system}[#{ua}] failed"
    end
  end
end
puts "parsing passed"

tests['browser']['version'].each do |ua|
  user_agent = UserAgent.find(ua['user_agent'])
  unless ua['version'] == user_agent.browser_version
    puts "exected #{ua['version'].inspect} -> #{user_agent.browser_version}"
    raise "#{ua['user_agent']} failed\n"
  end
end
puts "UserAgent.browser_version passed"


