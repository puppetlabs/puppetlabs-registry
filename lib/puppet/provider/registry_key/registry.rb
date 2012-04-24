# REMIND: need to support recursive delete of subkeys & values

Puppet::Type.type(:registry_key).provide(:registry) do
  require 'puppet/modules/registry/registry_base'
  include Puppet::Modules::Registry::RegistryBase

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
    keypath.hkey.create(keypath.subkey, access(Win32::Registry::KEY_ALL_ACCESS)) {|reg| true }
  end

  def exists?
    Puppet.debug("exists? key #{resource[:path]}")
    !!keypath.hkey.open(keypath.subkey, access(Win32::Registry::KEY_READ)) {|reg| true } rescue false
  end

  def destroy
    Puppet.debug("destroy key #{resource[:path]}")

    raise "Cannot delete root key: #{resource[:path]}" unless keypath.subkey

    if RegDeleteKeyEx.call(keypath.hkey.hkey, keypath.subkey, access, 0) != 0
      raise "Failed to delete registry key: #{resource[:path]}"
    end
  end

  def keypath
    @keypath ||= resource.parameter(:path)
  end
end
