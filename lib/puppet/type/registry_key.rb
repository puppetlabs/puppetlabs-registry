require 'puppet/type'
Puppet::Type.newtype(:registry_key) do
  require 'pathname' # JJM WORK_AROUND #14073
  require Pathname.new(__FILE__).dirname.dirname.expand_path + 'modules/registry/registry_base'
  require Pathname.new(__FILE__).dirname.dirname.expand_path + 'modules/registry/key_path'
  extend Puppet::Modules::Registry::RegistryBase

  def self.title_patterns
    [ [ /^(.*?)\Z/m, [ [ :path, lambda{|x| x} ] ] ] ]
  end

  ensurable

  newparam(:path, :parent => Puppet::Modules::Registry::KeyPath, :namevar => true) do
  end

  newparam(:purge_values, :boolean => true) do
    desc "Whether to delete any registry value associated with this key that is not being managed by puppet."
    newvalues(:true, :false)
    defaultto false

    validate do |value|
      case value
      when true, /^true$/i, :true, false, /^false$/i, :false, :undef, nil
        true
      else
        # We raise an ArgumentError and not a Puppet::Error so we get manifest
        # and line numbers in the error message displayed to the user.
        raise ArgumentError.new("Validation Error: purge_values must be true or false, not #{value}")
      end
    end

    munge do |value|
      case value
      when true, /^true$/i, :true
        true
      else
        false
      end
    end
  end

  # Autorequire the nearest ancestor registry_key found in the catalog.
  autorequire(:registry_key) do
    req = []
    if found = parameter(:path).enum_for(:ascend).find { |p| catalog.resource(:registry_key, p.to_s) }
      req << found.to_s
    end
    req
  end

  def eval_generate
    # This value will be given post-munge so we can assume it will be a ruby true or false object
    return [] unless value(:purge_values)

    # get the "should" names of registry values associated with this key
    should_values = catalog.relationship_graph.direct_dependents_of(self).select {|dep| dep.type == :registry_value }.map do |reg|
      reg.parameter(:path).valuename
    end

    # get the "is" names of registry values associated with this key
    is_values = provider.values

    # create absent registry_value resources for the complement
    resources = []
    (is_values - should_values).each do |name|
      resources << Puppet::Type.type(:registry_value).new(:path => "#{self[:path]}\\#{name}", :ensure => :absent)
    end
    resources
  end
end
