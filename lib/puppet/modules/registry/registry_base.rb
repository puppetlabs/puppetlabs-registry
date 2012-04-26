require 'pathname' # JJM WORK_AROUND #14073
require Pathname.new(__FILE__).dirname.expand_path

module Puppet::Modules::Registry::RegistryBase
  if Puppet.features.microsoft_windows?
    begin
      require 'win32/registry'
    rescue LoadError => exc
      msg = "Could not load the required win32/registry library (ErrorID 1EAD86E3-D533-4286-BFCB-CCE8B818DDEA) [#{exc.message}]"
      Puppet.err msg
      error = Puppet::Error.new(msg)
      error.set_backtrace exc.backtrace
      raise error
    end
  end

  # REG_DWORD_BIG_ENDIAN REG_LINK
  # REG_RESOURCE_LIST REG_FULL_RESOURCE_DESCRIPTOR
  # REG_RESOURCE_REQUIREMENTS_LIST

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

  def hkeys
    {
      :hkcr => Win32::Registry::HKEY_CLASSES_ROOT,
      :hklm => Win32::Registry::HKEY_LOCAL_MACHINE,
    }
  end
end
