require 'puppet/type'
require 'pathname' # JJM WORK_AROUND #14073
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'modules/registry/type_value_base'
Puppet::Type.newtype(:registry_value) do
  include Puppet::Modules::Registry::TypeValueBase

  def self.title_patterns
    [ [ /^(.*?)\Z/m, [ [ :path, lambda{|x| x} ] ] ] ]
  end

  ensurable

  newparam(:path, :namevar => true) do
    include Puppet::Modules::Registry::TypeValueBase
    desc "REVISIT: The path to the registry value"
    validate do |path|
      newpath(path).valid?
    end
    munge do |path|
      newpath(path).canonical
    end
  end

  newproperty(:type) do
    newvalues(:string, :array, :dword, :qword, :binary, :expand)
    defaultto :string
  end

  newproperty(:data, :array_matching => :all) do
    desc "The data of the registry value."

    defaultto ''

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
      when :binary
        unless value.match(/^([a-f\d]{2} ?)*$/i)
          fail("The data must be a hex encoded string of the form: '00 01 02 ...'")
        end
        # First, strip out all spaces from the string in the manfest.  Next,
        # put a space after each pair of hex digits.  Strip off the rightmost
        # space if it's present.  Finally, downcase the whole thing.  The final
        # result should be: "CaFE BEEF" => "ca fe be ef"
        value.gsub(/\s+/, '').gsub(/([0-9a-f]{2})/i) { "#{$1} " }.rstrip.downcase
      else #:string, :expand, :array
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

    def change_to_s(currentvalue, newvalue)
      if currentvalue.respond_to? :join
        currentvalue = currentvalue.join(",")
      end
      if newvalue.respond_to? :join
        newvalue = newvalue.join(",")
      end
      super(currentvalue, newvalue)
    end
  end

  # Autorequire the nearest ancestor registry_key found in the catalog.
  autorequire(:registry_key) do
    req = []
    path = newpath(value(:path))
    if found = path.enum_for(:ascend).find { |p| catalog.resource(:registry_key, p.to_s) }
      req << found.to_s
    end
    req
  end
end

