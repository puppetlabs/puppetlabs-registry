require 'puppet/modules/registry/registry_base'
require 'puppet/modules/registry/value_path'

Puppet::Type.newtype(:registry_value) do
  include Puppet::Modules::Registry::RegistryBase

  def self.title_patterns
    [ [ /^(.*?)\Z/m, [ [ :path, lambda{|x| x} ] ] ] ]
  end

  ensurable

  newparam(:path, :parent => Puppet::Modules::Registry::ValuePath, :namevar => true) do
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
    parameter(:path).enum_for(:ascend)
  end
end

