require 'puppet/util/registry_base'

Puppet::Type.newtype(:registry_value) do
  include Puppet::Util::RegistryBase

  def self.title_patterns
    [ [ /^(.*?)\Z/m, [ [ :path, lambda{|x| x} ] ] ] ]
  end

  attr_accessor :hkey, :subkey, :valuename

  ensurable

  newparam(:path, :namevar => true) do
    validate do |path|
      # really we should have a RegistryPath parameter, with hkey, etc readers
      resource.hkey, resource.subkey, resource.valuename = resource.value_split(path.to_s)
    end
  end

  newparam(:redirect) do
    newvalues(:true, :false)
    defaultto :false
  end

  newproperty(:type) do
    newvalues(:string, :array, :dword, :qword, :binary, :expand)
    defaultto :string
  end

  newproperty(:data) do
    desc "The data of the registry value."

    munge do |value|
      case resource[:type]
      when :dword, :qword
        Integer(value)
      when :array
        # REMIND: this is not supported yet
        value
      when :binary
        value
      else #:string, :expand
        value
      end
    end

    defaultto ''
  end

  autorequire(:registry_key) do
    parents = []
    ascend(hkey, subkey) do |h, s|
      parents << "#{h}\\#{s}"
    end
    parents
  end
end

