module PuppetX
module Puppetlabs
module Registry
  # For 64-bit OS, use 64-bit view. Ignored on 32-bit OS
  KEY_WOW64_64KEY = 0x100
  # For 64-bit OS, use 32-bit view. Ignored on 32-bit OS
  KEY_WOW64_32KEY = 0x200 unless defined? KEY_WOW64_32KEY

  # This is the base class for Path manipulation.  This class is meant to be
  # abstract, RegistryKeyPath and RegistryValuePath will customize and override
  # this class.
  class RegistryPathBase < String
    attr_reader :path
    def initialize(path)
      @filter_path_memo = nil
      @path ||= path
      super(path)
    end

    # The path is valid if we're able to parse it without exceptions.
    def valid?
      (filter_path and true) rescue false
    end

    def canonical
      filter_path[:canonical]
    end

    # This method is meant to help setup aliases so autorequire can sort itself
    # out in a case insensitive but preserving manner.  It returns an array of
    # resource identifiers.
    def aliases
      [canonical.downcase]
    end

    def access
      filter_path[:access]
    end

    def root
      filter_path[:root]
    end

    def subkey
      filter_path[:trailing_path]
    end

    def ascend(&block)
      p = canonical
      while idx = p.rindex('\\')
        p = p[0, idx]
        yield p
      end
    end

    private

    def filter_path
      if @filter_path_memo
        return @filter_path_memo
      end
      result = {}

      path = @path
      # Strip off any trailing slash.
      path = path.gsub(/\\*$/, '')

      unless captures = /^(32:)?([h|H][^\\]*)((?:\\[^\\]{1,255})*)$/.match(path)
        raise ArgumentError, "Invalid registry key: #{path}"
      end

      case captures[1]
      when '32:'
        result[:access] = PuppetX::Puppetlabs::Registry::KEY_WOW64_32KEY
        result[:prefix] = '32:'
      else
        result[:access] = PuppetX::Puppetlabs::Registry::KEY_WOW64_64KEY
        result[:prefix] = ''
      end

      # canonical root key symbol
      result[:root] = case captures[2].to_s.downcase
              when /hkey_local_machine/, /hklm/
                :hklm
              when /hkey_classes_root/, /hkcr/
                :hkcr
              when /hkey_users/, /hku/
                :hku
              when /hkey_current_user/, /hkcu/,
                /hkey_current_config/, /hkcc/,
                /hkey_performance_data/,
                /hkey_performance_text/,
                /hkey_performance_nlstext/,
                /hkey_dyn_data/
                raise ArgumentError, "Unsupported predefined key: #{path}"
              else
                raise ArgumentError, "Invalid registry key: #{path}"
              end

      result[:trailing_path] = captures[3]

      result[:trailing_path].gsub!(/^\\/, '')

      if result[:trailing_path].empty?
        result[:canonical] = "#{result[:prefix]}#{result[:root].to_s}"
      else
        # Leading backslash is not part of the subkey name
        result[:canonical] = "#{result[:prefix]}#{result[:root].to_s}\\#{result[:trailing_path]}"
      end

      @filter_path_memo = result
    end
  end

  class RegistryKeyPath < RegistryPathBase
  end

  class RegistryValuePath < RegistryPathBase
    attr_reader :valuename

    # Extract the valuename from the path and then munge the actual path
    def initialize(path)
      @valuename = case path[-1, 1]
      when '\\'
        @is_default = true
        ''
      else
        @is_default = false
        idx = path.rindex('\\') || 0
        if idx > 0
          val = path[idx+1..-1]
          # Strip the valuename from the path
          path = path[0..idx-1]
          val
        else
          ''
        end
      end

      super(path)
    end

    def canonical
      # Because we extracted the valuename in the initializer we
      # need to add it back in when canical is called
      filter_path[:canonical] + '\\' + valuename
    end

    def default?
      @is_default
    end

    def filter_path
      result = super

      # It's possible to pass in a path of 'hklm' which can still be parsed, but is not valid registry key.  Only the default value 'hklm\'
      # and named values 'hklm\something' are allowed
      raise ArgumentError, "Invalid registry key: #{path}" if result[:trailing_path].empty? && valuename.empty? && !default?

      result
    end
  end
end
end
end
