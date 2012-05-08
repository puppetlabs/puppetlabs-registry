# REMIND: need to support recursive delete of subkeys & values
require 'pathname' # JJM WORK_AROUND #14073
require Pathname.new(__FILE__).dirname.dirname.dirname.expand_path + 'modules/registry'
require Pathname.new(__FILE__).dirname.dirname.dirname.expand_path + 'modules/registry/provider_base'

Puppet::Type.type(:registry_key).provide(:registry) do
  include Puppet::Modules::Registry::ProviderBase

  defaultfor :operatingsystem => :windows
  confine    :operatingsystem => :windows

  def self.instances
    hkeys.keys.collect do |hkey|
      new(:provider => :registry, :name => "#{hkey.to_s}")
    end
  end

  def create
    Puppet.debug("Creating registry key #{self}")
    hive.create(subkey, Win32::Registry::KEY_ALL_ACCESS | access) {|reg| true }
  end

  def exists?
    Puppet.debug("Checking existence of registry key #{self}")
    !!hive.open(subkey, Win32::Registry::KEY_READ | access) {|reg| true } rescue false
  end

  def destroy
    Puppet.debug("Destroying registry key #{self}")

    raise ArgumentError, "Cannot delete root key: #{path}" unless subkey
    reg_delete_key_ex = Win32API.new('advapi32', 'RegDeleteKeyEx', 'LPLL', 'L')

    # hive.hkey returns an integer value that's like a FD
    if reg_delete_key_ex.call(hive.hkey, subkey, access, 0) != 0
      raise "Failed to delete registry key: #{self}"
    end
  end

  def values
    names = []
    # Only try and get the values for this key if the key itself exists.
    if exists? then
      hive.open(subkey, Win32::Registry::KEY_READ | access) do |reg|
        reg.each_value do |name, type, data| names << name end
      end
    end
    names
  end

  private

  def path
    @path ||= Puppet::Modules::Registry::RegistryKeyPath.new(resource.parameter(:path).value)
  end
end
