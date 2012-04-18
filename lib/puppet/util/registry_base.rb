module Puppet::Util::RegistryBase
  require 'win32/registry'

  HKEYS = {
    :hkcr => Win32::Registry::HKEY_CLASSES_ROOT,
    :hklm => Win32::Registry::HKEY_LOCAL_MACHINE,
    #:hku  => Win32::Registry::HKEY_USERS,
    #:hkcu => HKEY_CURRENT_USER,
  }

  TYPE2NAME = {
    Win32::Registry::REG_NONE => :none,
    Win32::Registry::REG_SZ   => :string,
    Win32::Registry::REG_EXPAND_SZ => :expand,
    Win32::Registry::REG_BINARY => :binary,
    Win32::Registry::REG_DWORD => :dword,
    Win32::Registry::REG_QWORD => :qword,
    Win32::Registry::REG_MULTI_SZ => :array
  }

  # REG_DWORD_BIG_ENDIAN REG_LINK
  # REG_RESOURCE_LIST REG_FULL_RESOURCE_DESCRIPTOR
  # REG_RESOURCE_REQUIREMENTS_LIST

  NAME2TYPE = {}
  TYPE2NAME.each_pair {|k,v| NAME2TYPE[v] = k}

  def type2name(type)
    return TYPE2NAME[type]
  end

  def name2type(name)
    return NAME2TYPE[name]
  end

  def hkeys
    HKEYS
  end

  def ascend(hkey, subkey, &block)
    yield hkey, subkey

    while idx = subkey.rindex('\\')
      subkey = subkey[0, idx]
      yield hkey, subkey
    end
  end

  def key_split(path)
    rootkey, subkey = path.split('\\', 2)

    hkey =
        case rootkey.downcase
        when /hkey_local_machine/, /hklm/
          HKEYS[:hklm]
        when /hkey_classes_root/, /hkcr/
          HKEYS[:hkcr]
        else
          raise ArgumentError, "Unsupported prefined key: #{path}"
        end

    [hkey, subkey]
  end

  def value_split(path, default = nil)
    if default == :true
      hkey, subkey = key_split(path)
      value = ''
    else
      idx = path.rindex('\\')
      raise ArgumentError, "Registry value path must contain at least one backslash." unless idx

      hkey, subkey = key_split(path[0, idx])
      value = path[idx+1..-1] if idx > 0
    end
    [hkey, subkey, value]
  end

  def access(mask = 0)
    # REMIND: skip this if 32-bit OS?
    #:redirect) == :true ? 0x200 : 0x100)
    mask | (resource[:redirect] == 'true' ? 0x200 : 0x100)
  end
end
