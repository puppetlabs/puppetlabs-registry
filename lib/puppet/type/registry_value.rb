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

  newproperty(:type) do
    newvalues(:string, :array, :dword, :qword, :binary, :expand)
    defaultto :string
  end

  newproperty(:data) do
    desc "The data of the registry value."

    munge do |value|
      case resource[:type]
      when :dword
        val = Integer(value) rescue nil
        fail("The data must be a valid DWORD: #{value}") unless val and (val.abs >> 32) <= 0
        val
      when :qword
        val = Integer(value) rescue nil
        fail("The data must be a valid QWORD: #{value}") unless val and (val.abs >> 64) <= 0
        val
      when :array
        # REMIND: this is not supported yet
        value
      when :binary
        unless value.match(/^([a-f\d]{2} ?)*$/i)
          fail("The data must be a hex encoded string of the form: '00 01 02 ...'")
        end
        value
      else #:string, :expand
        value
      end
    end

    def property_matches?(current, desired)
      case resource[:type]
      when :binary
        return false unless current
        current.casecmp(desired) == 0
      else
        super(current, desired)
      end
    end

    defaultto ''
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

