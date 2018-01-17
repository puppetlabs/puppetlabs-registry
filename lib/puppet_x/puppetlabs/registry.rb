module PuppetX
module Puppetlabs
module Registry
  # For 64-bit OS, use 64-bit view. Ignored on 32-bit OS
  KEY_WOW64_64KEY = 0x100
  # For 64-bit OS, use 32-bit view. Ignored on 32-bit OS
  KEY_WOW64_32KEY = 0x200 unless defined? KEY_WOW64_32KEY

  # Helper methods used in the registry providers
  # Guarded to only load on Windows due to Win32 constants
  if Puppet.features.microsoft_windows?
    def self.hkeys
      {
        :hkcr => Win32::Registry::HKEY_CLASSES_ROOT,
        :hklm => Win32::Registry::HKEY_LOCAL_MACHINE,
        :hku  => Win32::Registry::HKEY_USERS,
      }
    end

    def self.hive
      hkeys[root]
    end

    def self.type2name_map
      {
        Win32::Registry::REG_NONE      => :none,
        Win32::Registry::REG_SZ        => :string,
        Win32::Registry::REG_EXPAND_SZ => :expand,
        Win32::Registry::REG_BINARY    => :binary,
        Win32::Registry::REG_DWORD     => :dword,
        Win32::Registry::REG_QWORD     => :qword,
        Win32::Registry::REG_MULTI_SZ  => :array
      }
    end

    def self.type2name(type)
      type2name_map[type]
    end

    def self.name2type(name)
      name2type = {}
      type2name_map.each_pair {|k,v| name2type[v] = k}
      name2type[name]
    end
  end

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

    # Combines a registry key path and valuename into a resource title for
    # registry_value resource.
    #
    # To maintain backwards compatibility, only use the double backslash
    # delimiter if the valuename actually contains a backslash
    def self.combine_path_and_value(keypath, valuename)
      if valuename.include?('\\')
        keypath + '\\\\' + valuename
      else
        keypath + '\\' + valuename
      end
    end


    # Extract the valuename from the path and then munge the actual path
    def initialize(path)
      # Try finding the valuename via the double backslash method first
      # and then revert to the old single backslash way
      dbl_slash_idx = path.index('\\\\') || 0
      if dbl_slash_idx > 0
        # If the user specified a double backslash, split the string there
        # Strip the valuename from the path
        @valuename = path[dbl_slash_idx+2..-1]
        @is_default = @valuename.empty?
        path = path[0..dbl_slash_idx-1]
      else
        # This older method splits the string at the last single backslash
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
      end

      super(path)
    end

    def canonical
      # Because we extracted the valuename in the initializer we
      # need to add it back in when canonical is called.
      if valuename.include?('\\')
        filter_path[:canonical] + '\\\\' + valuename
      else
        filter_path[:canonical] + '\\' + valuename
      end
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
