require 'puppet/type'
require 'pathname' # JJM WORK_AROUND #14073
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'modules/registry'

Puppet::Type.newtype(:registry_value) do
  def self.title_patterns
    [ [ /^(.*?)\Z/m, [ [ :path, lambda{|x| x} ] ] ] ]
  end

  ensurable

  newparam(:path, :namevar => true) do
    desc <<-'EODESC'
The path to the registry value to manage.  For example; 'HKLM\Software\Value1',
'HKEY_LOCAL_MACHINE\Software\Vendor\Value2'.  If Puppet is running on a 64 bit
system, the 32 bit registry key can be explicitly manage using a prefix.  For
example: '32:HKLM\Software\Value3'
    EODESC
    validate do |path|
      Puppet::Modules::Registry::RegistryValuePath.new(path).valid?
    end
    munge do |path|
      Puppet::Modules::Registry::RegistryValuePath.new(path).canonical
    end
  end

  newproperty(:type) do
    desc <<-'EODESC'
The Windows data type of the registry value.  Puppet provides helpful names for
these types as follows:

 * string => REG_SZ
 * array  => REG_MULTI_SZ
 * expand => REG_EXPAND_SZ
 * dword  => REG_DWORD
 * qword  => REG_QWORD
 * binary => REG_BINARY
    EODESC
    newvalues(:string, :array, :dword, :qword, :binary, :expand)
    defaultto :string
  end

  newproperty(:data, :array_matching => :all) do
    desc <<-'EODESC'
The data stored in the registry value.  Data should be specified as a string
value but may be specified as a Puppet array when the type is set to 'array'.
    EODESC

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
    path = Puppet::Modules::Registry::RegistryKeyPath.new(value(:path))
    if found = path.enum_for(:ascend).find { |p| catalog.resource(:registry_key, p.to_s) }
      req << found.to_s
    end
    req
  end
end
