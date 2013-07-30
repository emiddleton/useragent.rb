require 'yaml'

class UserAgent
  class OperatingSystem
    @@operating_systems = {}

    attr_reader :id, :key, :name

    def self.load(ua)
      @@manufacturers = ua['manufacturers']
      ua['operating_systems'].each do |name,operating_system|
        load_operating_system(name,operating_system)
      end
    end

    def self.load_operating_system(name,operating_system)
      b = OperatingSystem.new(name,operating_system)
      @@operating_systems[name.to_sym] = b
      # create children
      if operating_system['children']
        operating_system['children'].each do |child_name,child_operating_system|
          child_operating_system['parent'] = name.to_sym
          load_operating_system(child_name,child_operating_system)
        end
      end
    end

    def initialize(name, operating_system)
  #    puts "loading: #{name}"
      @parent        = operating_system['parent']
      @manufacturer  = operating_system['manufacturer'].to_s
      @id            = (@@manufacturers[manufacturer]['id'] << 8) + operating_system['id']
      @key           = name
      @name          = operating_system['name']
      @children      = operating_system['children'].keys if operating_system['children']
      @aliases       = operating_system['aliases']
      @exclude_list  = operating_system['exclude_list'] || []
      @device_type   = operating_system['device_type']

      @@operating_systems[@parent].children << name if @parent
    end

    def device_type
      @device_type.nil? ? self.parent.device_type : @device_type
    end

    def manufacturer
      @manufacturer.empty? ? self.parent.manufacturer : @manufacturer
    end

    def parent
      @@operating_systems[@parent]
    end

    def each_child(&block)
      @children.each do |child|
        yield @@operating_systems[child.to_sym]
      end
    end

    def mobile?
      @device_type == 'mobile'
    end

    def alias_matched?(ua)
      @aliases.each do |a|
        if ua.downcase.index(a.downcase)
          return true
        end
      end
      false
    end

    def exclusion_matched?(ua)
      @exclude_list.each do |exclusion|
        if ua.downcase.index(exclusion.downcase)
          return true
        end
      end
      false
    end

    def matched?(ua)
      if alias_matched?(ua)
        if children.size > 0
          each_child do |child|
            os = child.matched?(ua)
            if os
#              puts "checking2: #{child.name}"
              return os
            end
          end
        end
        unless exclusion_matched?(ua)
#          puts "checking3: #{self.name}"
          return self
        end
      end
      nil
    end

    def self.find(ua)
      @@operating_systems.each do |name,operating_system|
#        puts "checking1: #{name}"
        if operating_system.parent.nil?
          os = operating_system.matched?(ua)
          if os
#            puts "checking4: #{os.name}"
            return os
          end
        end
      end
      return @@operating_systems[:unknown]
    end

    protected
      def children
        @children ||= []
      end

      def self.find_key(key)
        @@operating_systems[key]
      end
  end

  class Browser
    @@browsers = {}

    attr_reader :id, :key, :name, :manufacturer, :rendering_engine

    def self.load(ua)
      @@manufacturers = ua['manufacturers']
      ua['browsers'].each do |name,browser|
        load_browser(name,browser)
      end
    end

    def self.load_browser(name,browser)
      b = Browser.new(name,browser)
      @@browsers[name.to_sym] = b
      # create children
      if browser['children']
        browser['children'].each do |child_name,child_browser|
          child_browser['parent'] = name.to_sym
          load_browser(child_name,child_browser)
        end
      end
    end

    def initialize(name,browser)
      #puts "loading: #{name}"
      @parent           = browser['parent']
      @manufacturer     = browser['manufacturer'].to_s
      @id               = (@@manufacturers[manufacturer]['id'] << 8) + browser['id']
      @key              = name
      @name             = browser['name']
      @children         = browser['children'].keys if browser['children']
      @aliases          = browser['aliases']
      @exclude_list     = browser['exclude_list'] || []
      @browser_type     = browser['browser_type'].to_s
      @rendering_engine = browser['rendering_engine']
      @version_regex    = browser['version_regex']

      @@browsers[@parent].children << name if @parent
    end

    def browser_type
      @browser_type.empty? ? self.parent.browser_type : @browser_type
    end

    def manufacturer
      @manufacturer.empty? ? self.parent.manufacturer : @manufacturer
    end

    def parent
      @@browsers[@parent]
    end

    def each_child(&block)
      @children.each do |child|
        yield @@browsers[child.to_sym]
      end
    end

    def version_regex
      if @version_regex.nil? and self.parent
        parent.version_regex
      else
        @version_regex
      end
    end

    def version(ua)
      return nil unless self.version_regex
      if ua =~ /#{self.version_regex}/
        full,major,minor = $1,$2,$3
        minor ||= '0'
        return {'full'=>full, 'major'=>major, 'minor'=>minor}
      else
        return nil
      end
    end

    def alias_matched?(ua)
      @aliases.each do |a|
        if ua.downcase.index(a.downcase)
          return true
        end
      end
      false
    end

    def exclusion_matched?(ua)
      @exclude_list.each do |exclusion|
        if ua.downcase.index(exclusion.downcase)
          return true
        end
      end
      false
    end

    def matched?(ua)
      if alias_matched?(ua)
        if children.size > 0
          each_child do |child|
            b = child.matched?(ua)
            if b
  #            puts "checking2: #{b.name}"
              return b
            end
          end
        end
        unless exclusion_matched?(ua)
  #        puts "checking3: #{self.name}"
          return self
        end
      end
      nil
    end

    def self.find(ua)
      @@browsers.each do |name,browser|
#        puts "checking1: #{name}"
        if browser.parent.nil?
          b = browser.matched?(ua)
          if b
  #          puts "checking4: #{b.name}"
            return b
          end
        end
      end
      return @@browsers[:unknown]
    end

    protected
      def children
        @children ||= []
      end
  end

  def self.load_file(file)
    load(YAML.load_file(file))
  end

  def self.load(ua)
    OperatingSystem.load(ua)
    Browser.load(ua)
  end

  def self.find(ua)
    self.new(ua)
  end

  attr_reader :id, :browser, :operating_system, :user_agent

  def browser_version
    @browser.version(@user_agent)
  end

  def initialize(ua)
    @browser = Browser.find(ua)
    #puts ua
    if @browser.browser_type == :bot
      @operating_system = OperatingSystem.find_key(:unknown)
    else
      @operating_system = OperatingSystem.find(ua)
    end
    #puts @operating_system.inspect
    @id = @operating_system.id << 16 + @browser.id
    @user_agent = ua
  end
end
