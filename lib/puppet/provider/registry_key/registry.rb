# REMIND: need to support recursive delete of subkeys & values
begin
  # We expect this to work once Puppet supports Rubygems in #7788
  require 'puppet_x/puppetlabs/registry'
rescue LoadError
  # Work around #7788 (Rubygems support for modules)
  require 'pathname' # JJM WORK_AROUND #14073
  module_base = Pathname.new(__FILE__).dirname
  require module_base + '../../../' + 'puppet_x/puppetlabs/registry'
end
Puppet::Type.type(:registry_key).provide(:registry) do
  desc <<-DOC
   @summary Registry_key provider
   Manages individual Registry keys.
  DOC
  include Puppet::Util::Windows::Registry if Puppet.features.microsoft_windows?

  defaultfor operatingsystem: :windows
  confine    operatingsystem: :windows

  def self.instances
    PuppetX::Puppetlabs::Registry.hkeys.keys.map do |hkey|
      new(provider: :registry, name: hkey.to_s)
    end
  end

  def hive
    PuppetX::Puppetlabs::Registry.hkeys[path.root]
  end

  def access
    path.access
  end

  def subkey
    path.subkey
  end

  def create
    Puppet.debug("Creating registry key #{self}")
    hive.create(subkey, Win32::Registry::KEY_ALL_ACCESS | access) { |_reg| true }
  end

  def exists?
    Puppet.debug("Checking existence of registry key #{self}")
    begin
      !!hive.open(subkey, Win32::Registry::KEY_READ | access) { |_reg| true } # rubocop:disable Style/DoubleNegation
    rescue
      false
    end
  end

  def destroy
    Puppet.debug("Destroying registry key #{self}")

    raise ArgumentError, "Cannot delete root key: #{path}" unless subkey
    delete_key(hive, subkey, access)
  end

  def values
    names = []
    # Only try and get the values for this key if the key itself exists.
    if exists?
      hive.open(subkey, Win32::Registry::KEY_READ | access) do |reg|
        each_value(reg) { |name, _type, _data| names << name }
      end
    end
    names
  end

  private

  def path
    @path ||= PuppetX::Puppetlabs::Registry::RegistryKeyPath.new(resource.parameter(:path).value)
  end
end
