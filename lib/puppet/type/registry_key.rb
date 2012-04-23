require 'puppet/modules/registry/registry_base'
require 'puppet/modules/registry/key_path'

Puppet::Type.newtype(:registry_key) do
  include Puppet::Modules::Registry::RegistryBase

  def self.title_patterns
    [ [ /^(.*?)\Z/m, [ [ :path, lambda{|x| x} ] ] ] ]
  end

  ensurable

  newparam(:path, :parent => Puppet::Modules::Registry::KeyPath, :namevar => true) do
  end

  newparam(:redirect) do
    newvalues(:true, :false)
    defaultto :false
  end

  autorequire(:registry_key) do
    parameter(:path).enum_for(:ascend).select { |p| self[:path] != p }
  end
end
