Puppet::Type.type(:registry_value).provide(:registry) do
  require 'puppet/util/registry_base'
  include Puppet::Util::RegistryBase

  defaultfor :operatingsystem => :windows
  confine    :operatingsystem => :windows

  RegQueryValueExA = Win32API.new('advapi32', 'RegQueryValueEx', 'LPLPPP', 'L')

  def self.instances
    []
  end

  def create
    Puppet.info("creating: #{self}")

    resource.hkey.open(resource.subkey, access(Win32::Registry::KEY_ALL_ACCESS)) do |reg|
      reg.write(resource.valuename, name2type(resource[:type]), resource[:data])
    end
  end

  def exists?
    Puppet.info("exists: #{self}")

    found = false
    resource.hkey.open(resource.subkey, access(Win32::Registry::KEY_READ)) do |reg|
      type = [0].pack('L')
      size = [0].pack('L')
      found = RegQueryValueExA.call(reg.hkey, resource.valuename, 0, type, 0, size) == 0
    end
    found
  end

  def flush
    Puppet.info("flushing: #{self}")

    # REMIND: not during destroy

    resource.hkey.open(resource.subkey, access(Win32::Registry::KEY_ALL_ACCESS)) do |reg|
      reg.write(resource.valuename, name2type(regvalue[:type]), regvalue[:data])
    end
  end

  def destroy
    Puppet.info("destroying: #{self}")

    resource.hkey.open(resource.subkey, access(Win32::Registry::KEY_ALL_ACCESS)) do |reg|
      reg.delete_value(resource.valuename)
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
      resource.hkey.open(resource.subkey, access(Win32::Registry::KEY_ALL_ACCESS)) do |reg|
        type = [0].pack('L')
        size = [0].pack('L')

        if RegQueryValueExA.call(reg.hkey, resource.valuename, 0, type, 0, size) == 0
          is_type, is_data = reg.read(resource.valuename)
          @regvalue[:type], @regvalue[:data] = type2name(is_type), is_data
        end
      end
    end
    @regvalue
  end

  def to_s
    "#{resource.hkey.keyname}\\#{resource.subkey}\\#{resource.valuename}"
  end
end
