require 'puppet/util/registry_base'

Puppet::Type.newtype(:registry_key) do
  include Puppet::Util::RegistryBase

  def self.title_patterns
    [ [ /^(.*?)\Z/m, [ [ :path, lambda{|x| x} ] ] ] ]
  end

  ensurable

  newparam(:path, :namevar => true) do
    validate do |value|
      resource.key_split(value.to_s)
    end
  end

  newparam(:redirect) do
    newvalues(:true, :false)
    defaultto :false
  end

  autorequire(:registry_key) do
    hkey, subkey = key_split(self[:path])

    parents = []
    ascend(hkey, subkey) do |h, s|
      # skip ourselves
      parents << "#{h.keyname}\\#{s}" unless s == subkey
    end

    parents
  end
end
