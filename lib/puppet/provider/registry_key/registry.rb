# REMIND: need to support recursive delete of subkeys & values

Puppet::Type.type(:registry_key).provide(:registry) do
  require 'puppet/util/registry_base'
  include Puppet::Util::RegistryBase

  defaultfor :operatingsystem => :windows
  confine    :operatingsystem => :windows

  RegDeleteKeyEx = Win32API.new('advapi32', 'RegDeleteKeyEx', 'LPLL', 'L')

  def self.instances
    self::HKEYS.collect do |hkey|
      new(:provider => :registry,
          :name => "#{hkey.to_s}")
    end
  end

  def create
    Puppet.debug("create key #{resource[:path]}")
    hkey, subkey = key
    hkey.create(subkey, access(Win32::Registry::KEY_ALL_ACCESS)) {|reg| true }
  end

  def exists?
    Puppet.debug("exists? key #{resource[:path]}")
    hkey, subkey = key
    !!hkey.open(subkey, access(Win32::Registry::KEY_READ)) {|reg| true } rescue false
  end

  def destroy
    Puppet.debug("destroy key #{resource[:path]}")
    hkey, subkey = key

    raise "Cannot delete root key: #{resource[:path]}" unless subkey

    if RegDeleteKeyEx.call(hkey.hkey, subkey, access, 0) != 0
      raise "Failed to delete registry key: #{resource[:path]}"
    end
  end

  def key
    key_split(resource[:path])
  end
end
