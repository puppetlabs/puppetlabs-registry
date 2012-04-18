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
    Puppet.info("creating: #{self.to_s}")

    resource.hkey.create(resource.subkey, access(Win32::Registry::KEY_ALL_ACCESS)) do |reg|
      reg.write(resource.valuename, name2type(self.type), self.data)
    end
  end

  def exists?
    Puppet.info("exists: #{self.to_s}")

    resource.hkey.open(resource.subkey, access(Win32::Registry::KEY_READ)) do |reg|
      type = [0].pack('L')
      size = [0].pack('L')
      RegQueryValueExA.call(reg.hkey, resource.valuename, 0, type, 0, size) == 0
    end
  end

  def flush
    Puppet.info("flushing: #{self.to_s}")

    # resource.hkey.open(resource.subkey, access(Win32::Registry::KEY_ALL_ACCESS)) do |reg|
    #   is_type, is_data = reg.read(resource.valuename)
    #   type ||= is_type
    #   data ||= is_data
    #   reg.write(resource.valuename, type, data)
    # end
  end

  def destroy
    Puppet.info("destroying: #{self.to_s}")

    resource.hkey.open(resource.subkey, access(Win32::Registry::KEY_ALL_ACCESS)) do |reg|
      reg.delete_value(resource.valuename)
    end
  end

  def type
    resource[:type]
  end

  def type=(value)
    resource[:type] = value
  end

  def data
    resource[:data]
  end

  def data=(value)
    resource[:data] = value
  end

  def to_s
    "#{resource.hkey.keyname}\\#{resource.subkey}\\#{resource.valuename}"
  end
end
