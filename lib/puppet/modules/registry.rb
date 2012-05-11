require 'pathname'
# JJM WORK_AROUND
# explicitly require files without relying on $LOAD_PATH until #14073 is fixed.
# https://projects.puppetlabs.com/issues/14073 is fixed.
require Pathname.new(__FILE__).dirname.expand_path

module Puppet::Modules::Registry
  # For 64-bit OS, use 64-bit view. Ignored on 32-bit OS
  KEY_WOW64_64KEY = 0x100 unless defined? KEY_WOW64_64KEY
  # For 64-bit OS, use 32-bit view. Ignored on 32-bit OS
  KEY_WOW64_32KEY = 0x200 unless defined? KEY_WOW64_32KEY

  # This is the base class for Path manipulation.  This class is meant to be
  # abstract, RegistryKeyPath and RegistryValuePath will customize and override
  # this class.
  class RegistryPathBase < String
    attr_reader :path
    def initialize(path)
      @path ||= path
      super(path)
    end

    # The path is valid if we're able to parse it without exceptions.
    def valid?
      (filter_path and true) rescue false
    end

    def valuename
      filter_path[:valuename]
    end

    def canonical
      filter_path[:canonical]
    end

    def access
      filter_path[:access]
    end

    def root
      filter_path[:root]
    end

    def subkey
      filter_path[:subkey]
    end

    def default?
      !!filter_path[:is_default]
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
      result = {}

      path = @path

      result[:valuename] = case path[-1, 1]
      when '\\'
        result[:is_default] = true
        ''
      else
        result[:is_default] = false
        idx = path.rindex('\\') || 0
        if idx > 0
          path[idx+1..-1]
        else
          ''
        end
      end

      # Strip off any trailing slash.
      path = path.gsub(/\\*$/, '')

      unless captures = /^(32:)?([h|H][^\\]*)((?:\\[^\\]{1,255})*)$/.match(path)
        raise ArgumentError, "Invalid registry key: #{path}"
      end

      case captures[1]
      when '32:'
        result[:access] = Puppet::Modules::Registry::KEY_WOW64_32KEY
        result[:prefix] = '32:'
      else
        result[:access] = Puppet::Modules::Registry::KEY_WOW64_64KEY
        result[:prefix] = ''
      end

      # canonical root key symbol
      result[:root] = case captures[2].to_s.downcase
              when /hkey_local_machine/, /hklm/
                :hklm
              when /hkey_classes_root/, /hkcr/
                :hkcr
              when /hkey_current_user/, /hkcu/,
                /hkey_users/, /hku/,
                /hkey_current_config/, /hkcc/,
                /hkey_performance_data/,
                /hkey_performance_text/,
                /hkey_performance_nlstext/,
                /hkey_dyn_data/
                raise ArgumentError, "Unsupported prefined key: #{path}"
              else
                raise ArgumentError, "Invalid registry key: #{path}"
              end

      result[:subkey] = captures[3]

      if result[:subkey].empty?
        result[:canonical] = "#{result[:prefix]}#{result[:root].to_s}"
      else
        # Leading backslash is not part of the subkey name
        result[:subkey].sub!(/^\\(.*)$/, '\1')
        result[:canonical] = "#{result[:prefix]}#{result[:root].to_s}\\#{result[:subkey]}"
      end

      result
    end

  end

  class RegistryKeyPath < RegistryPathBase
    def valuename
      ''
    end
    def default?
      false
    end
  end

  class RegistryValuePath < RegistryPathBase
    def subkey
      filter_path[:subkey].gsub(/\\#{filter_path[:valuename]}/, '')
    end
  end
end
