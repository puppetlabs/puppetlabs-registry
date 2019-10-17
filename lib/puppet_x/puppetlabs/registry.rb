# @api private
# rubocop:disable Style/ClassAndModuleChildren
module PuppetX
  # @api private
  module Puppetlabs
    # @api private
    module Registry
      # rubocop:enable Style/ClassAndModuleChildren
      # For 64-bit OS, use 64-bit view. Ignored on 32-bit OS
      KEY_WOW64_64KEY = 0x100
      # For 64-bit OS, use 32-bit view. Ignored on 32-bit OS
      KEY_WOW64_32KEY = 0x200 unless defined? KEY_WOW64_32KEY

      def self.hkeys
        {
          hkcr: Win32::Registry::HKEY_CLASSES_ROOT,
          hklm: Win32::Registry::HKEY_LOCAL_MACHINE,
          hku: Win32::Registry::HKEY_USERS,
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
          Win32::Registry::REG_MULTI_SZ  => :array,
        }
      end

      def self.type2name(type)
        type2name_map[type]
      end

      def self.name2type(name)
        name2type = {}
        type2name_map.each_pair { |k, v| name2type[v] = k }
        name2type[name]
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
          (filter_path && true)
        rescue
          false
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

        def ascend
          p = canonical
          while idx = p.rindex('\\') # rubocop:disable Lint/AssignmentInCondition
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
          path = path.gsub(%r{\\*$}, '')

          captures = %r{^(32:)?([h|H][^\\]*)((?:\\[^\\]{1,255})*)$}.match(path)
          unless captures
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
                          when %r{hkey_local_machine}, %r{hklm}
                            :hklm
                          when %r{hkey_classes_root}, %r{hkcr}
                            :hkcr
                          when %r{hkey_users}, %r{hku}
                            :hku
                          when %r{hkey_current_user}, %r{hkcu},
                    %r{hkey_current_config}, %r{hkcc},
                    %r{hkey_performance_data},
                    %r{hkey_performance_text},
                    %r{hkey_performance_nlstext},
                    %r{hkey_dyn_data}
                            raise ArgumentError, "Unsupported predefined key: #{path}"
                          else
                            raise ArgumentError, "Invalid registry key: #{path}"
                          end

          result[:trailing_path] = captures[3]

          result[:trailing_path].gsub!(%r{^\\}, '')

          result[:canonical] = if result[:trailing_path].empty?
                                 "#{result[:prefix]}#{result[:root]}"
                               else
                                 # Leading backslash is not part of the subkey name
                                 "#{result[:prefix]}#{result[:root]}\\#{result[:trailing_path]}"
                               end

          @filter_path_memo = result
        end
      end

      class RegistryKeyPath < RegistryPathBase
      end

      # @summary Windows registry value path
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
          raise ArgumentError, "Invalid registry key: #{path}" unless path.include?('\\')

          # valuename appears after the the first double backslash
          path, @valuename = path.split('\\\\', 2)
          # no \\ but there is at least a single \ to split on
          path, _, @valuename = path.rpartition('\\') if @valuename.nil?
          @is_default = @valuename.empty?

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
