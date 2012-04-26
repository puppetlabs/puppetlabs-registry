require 'puppet/type'
Puppet::Type.newtype(:registry_key) do
  require 'pathname' # JJM WORK_AROUND #14073
  require Pathname.new(__FILE__).dirname.dirname.expand_path + 'modules/registry/registry_base'
  require Pathname.new(__FILE__).dirname.dirname.expand_path + 'modules/registry/key_path'
  include Puppet::Modules::Registry::RegistryBase

  def self.title_patterns
    [ [ /^(.*?)\Z/m, [ [ :path, lambda{|x| x} ] ] ] ]
  end

  ensurable

  newparam(:path, :parent => Puppet::Modules::Registry::KeyPath, :namevar => true) do
  end

  # Autorequire the nearest ancestor registry_key found in the catalog.
  autorequire(:registry_key) do
    req = []
    if found = parameter(:path).enum_for(:ascend).find { |p| catalog.resource(:registry_key, p.to_s) }
      req << found.to_s
    end
    req
  end
end
