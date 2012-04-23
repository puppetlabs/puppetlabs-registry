require 'puppet/modules/registry'

module Puppet::Modules::Registry::RegistryBase
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

  # For 64-bit OS, use 64-bit view. Ignored on 32-bit OS
  KEY_WOW64_64KEY = 0x100
  # For 64-bit OS, use 32-bit view. Ignored on 32-bit OS
  KEY_WOW64_32KEY = 0x200

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
end
