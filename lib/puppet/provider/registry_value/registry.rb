Puppet::Type.type(:registry_value).provide(:registry) do
  require 'puppet/modules/registry/registry_base'
  include Puppet::Modules::Registry::RegistryBase

  defaultfor :operatingsystem => :windows
  confine    :operatingsystem => :windows

  RegQueryValueExA = Win32API.new('advapi32', 'RegQueryValueEx', 'LPLPPP', 'L')

  def self.instances
    []
  end

  def create
    Puppet.info("creating: #{self}")

    valuepath.hkey.open(valuepath.subkey, Win32::Registry::KEY_ALL_ACCESS | valuepath.access) do |reg|
      reg.write(valuepath.valuename, name2type(resource[:type]), resource[:data])
    end
  end

  def exists?
    Puppet.info("exists: #{self}")

    found = false
    valuepath.hkey.open(valuepath.subkey, Win32::Registry::KEY_READ | valuepath.access) do |reg|
      type = [0].pack('L')
      size = [0].pack('L')
      found = RegQueryValueExA.call(reg.hkey, valuepath.valuename, 0, type, 0, size) == 0
    end
    found
  end

  def flush
    return if resource[:ensure] == :absent

    Puppet.info("flushing: #{self}")

    valuepath.hkey.open(valuepath.subkey, Win32::Registry::KEY_ALL_ACCESS | valuepath.access) do |reg|
      reg.write(valuepath.valuename, name2type(regvalue[:type]), regvalue[:data])
    end
  end

  def destroy
    Puppet.info("destroying: #{self}")

    valuepath.hkey.open(valuepath.subkey, Win32::Registry::KEY_ALL_ACCESS | valuepath.access) do |reg|
      reg.delete_value(valuepath.valuename)
    end
  end

  def type
    regvalue[:type] || :absent
  end

  def type=(value)
    regvalue[:type] = value
  end

  def data
    regvalue[:data] || :absent
  end

  def data=(value)
    regvalue[:data] = value
  end

  def regvalue
    unless @regvalue
      @regvalue = {}
      valuepath.hkey.open(valuepath.subkey, Win32::Registry::KEY_ALL_ACCESS | valuepath.access) do |reg|
        type = [0].pack('L')
        size = [0].pack('L')

        if RegQueryValueExA.call(reg.hkey, valuepath.valuename, 0, type, 0, size) == 0
          is_type, is_data = reg.read(valuepath.valuename)
          @regvalue[:type], @regvalue[:data] = type2name(is_type), is_data
        end
      end
    end
    @regvalue
  end

  def valuepath
    @valuepath ||= resource.parameter(:path)
  end

  def to_s
    "#{valuepath.hkey.keyname}\\#{valuepath.subkey}\\#{valuepath.valuename}"
  end
end
