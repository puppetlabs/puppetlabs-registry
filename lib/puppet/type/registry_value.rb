require 'puppet/util/registry_base'

Puppet::Type.newtype(:registry_value) do
  include Puppet::Util::RegistryBase

  def self.title_patterns
    [ [ /^(.*?)\Z/m, [ [ :path, lambda{|x| x} ] ] ] ]
  end

  attr_reader :hkey, :subkey, :valuename

  ensurable

  newparam(:path, :namevar => true) do
  end

  newparam(:redirect) do
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:default) do
    newvalues(:true, :false)
    defaultto :false
  end

  newproperty(:type) do
    newvalues(:string, :array, :dword, :qword, :binary, :expand)

    def insync?(currentvalue)
      require 'ruby-debug'; debugger
      super(currentvalue)
    end

    def property_matches?(current, desired)
      require 'ruby-debug'; debugger
      super(current, desired)
    end

    # munge do |value|
    #   require 'ruby-debug'; debugger
    #   resource.name2type(value.intern)
    # end

    # def is_to_s(currentvalue)
    #   type2name(currentvalue).to_s || currentvalue
    # end

    # def should_to_s(newvalue)
    #   type2name(newvalue).to_s || newvalue
    # end

    defaultto :string
  end

  newproperty(:data) do
    desc "The data of the registry value."
    defaultto ''

    # munge do |value|
    #   case resource[:type]
    #   when :string, :expand
    #     value
    #   when :dword, :qword
    #     require 'ruby-debug'; debugger
    #     Integer(value)
    #   when :binary
    #     value
    #   when :array
    #     value
    #   end
    # end

    # unmunge do |value|
    #   case resource[:type]
    #   when :string, :expand
    #     value
    #   when :dword, :qword
    #     require 'ruby-debug'; debugger
    #     value.to_s
    #   when :binary
    #     value
    #   when :array
    #     value
    #   end
    # end

    def insync?(currentvalue)
      require 'ruby-debug'; debugger
      super(currentvalue)
    end

    def property_matches?(current, desired)
      require 'ruby-debug'; debugger
      super(current, desired)
    end
  end

  validate do
    @hkey, @subkey, @valuename = value_split(self[:path], self[:default])
  end

  autorequire(:registry_key) do
    parents = []
    ascend(hkey, subkey) do |h, s|
      parents << "#{h}\\#{s}"
    end
    parents
  end
end

