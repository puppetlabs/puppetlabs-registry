
# This module is meant to be mixed into the registry_key AND registry_value providers.
module PuppetX
  module Puppetlabs
    module Registry
      module ProviderBase

        if Puppet.features.microsoft_windows?
          require 'ffi'
          extend FFI::Library

          require 'puppet/util/windows/registry'
          include Puppet::Util::Windows::Registry

          require 'puppet/util/windows/string'

          # https://msdn.microsoft.com/en-us/library/windows/desktop/ms724923(v=vs.85).aspx
          # LONG WINAPI RegSetValueEx(
          #   _In_             HKEY    hKey,
          #   _In_opt_         LPCTSTR lpValueName,
          #   _Reserved_       DWORD   Reserved,
          #   _In_             DWORD   dwType,
          #   _In_       const BYTE    *lpData,
          #   _In_             DWORD   cbData
          # );
          ffi_lib :advapi32
          attach_function :RegSetValueExW,
            [:handle, :pointer, :dword, :dword, :pointer, :dword], :win32_long

          def hkeys
            {
              :hkcr => Win32::Registry::HKEY_CLASSES_ROOT,
              :hklm => Win32::Registry::HKEY_LOCAL_MACHINE,
              :hku  => Win32::Registry::HKEY_USERS,
            }
          end
        else
          def hkeys
            {}
          end
        end

        def hive
          hkeys[root]
        end

        def access
          path.access
        end

        def root
          path.root
        end

        def subkey
          path.subkey
        end

        # The path method is expected to be mixed in by the provider
        # specific module, ProviderKeyBase or ProviderValueBase
        def path
          raise NotImplementedError
        end

        def type2name_map
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

        def type2name(type)
          type2name_map[type]
        end

        def name2type(name)
          name2type = {}
          type2name_map.each_pair {|k,v| name2type[v] = k}
          name2type[name]
        end
      end
    end
  end
end
