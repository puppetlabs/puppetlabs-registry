require 'puppet/util/registry_base'
require 'puppet/util/key_path'

Puppet::Type.newtype(:registry_key) do
  include Puppet::Util::RegistryBase

  def self.title_patterns
    [ [ /^(.*?)\Z/m, [ [ :path, lambda{|x| x} ] ] ] ]
  end

  ensurable

  newparam(:path, :parent => Puppet::Util::KeyPath, :namevar => true) do
  end

  newparam(:redirect) do
    newvalues(:true, :false)
    defaultto :false
  end

  autorequire(:registry_key) do
    parents = []
    path = parameter(:path)
    path.ascend do |hkey, subkey|
      parents << "#{hkey.keyname}\\#{subkey}" unless subkey == path.subkey # skip ourselves
    end
    parents
  end
end
