require 'puppet/type'
begin
  require 'puppet_x/puppetlabs/registry'
rescue LoadError
  require 'pathname' # JJM WORK_AROUND #14073 and #7788
  require Pathname.new(__FILE__).dirname + '../../' + 'puppet_x/puppetlabs/registry'
end

# @summary
#   Manages registry values on Windows systems.
#
# @note
#   The `registry_value` type can manage registry values.  See the
#   `type` and `data` attributes for information about supported
#   registry types, e.g. REG_SZ, and how the data should be specified.
#
#   **Autorequires:** Any parent registry key managed by Puppet will be
#   autorequired.
#
Puppet::Type.newtype(:registry_value) do
  @doc = <<-EOT
    Manages registry values on Windows systems.
  EOT
  def self.title_patterns
    [[%r{^(.*?)\Z}m, [[:path]]]]
  end

  ensurable

  # @summary
  #   The path to the registry value to manage.
  #
  # @example
  #   For example:
  #      'HKLM\Software\Value1', 'HKEY_LOCAL_MACHINE\Software\Vendor\Value2'.
  #      If Puppet is running on a 64-bit system, the 32-bit registry key can
  #      be explicitly managed using a prefix.
  # @example
  #   For example:
  #      '32:HKLM\Software\Value3'. Use a double backslash between the value name
  #      and path when managing a value with a backslash in the name."
  newparam(:path, namevar: true) do
    @doc = <<-EOT
      The path to the registry value to manage.
    EOT
    validate do |path|
      PuppetX::Puppetlabs::Registry::RegistryValuePath.new(path).valid?
    end
    munge do |path|
      reg_path = PuppetX::Puppetlabs::Registry::RegistryValuePath.new(path)
      # Windows is case insensitive and case preserving.  We deal with this by
      # aliasing resources to their downcase values.  This is inspired by the
      # munge block in the alias metaparameter.
      if @resource.catalog
        reg_path.aliases.each do |alt_name|
          @resource.catalog.alias(@resource, alt_name)
        end
      else
        Puppet.debug "Resource has no associated catalog.  Aliases are not being set for #{@resource}"
      end
      reg_path.canonical
    end
  end

  # @summary
  #   The Windows data type of the registry value.
  #
  #   Puppet provides helpful names for these types as follows:
  #     * string => REG_SZ
  #     * array  => REG_MULTI_SZ
  #     * expand => REG_EXPAND_SZ
  #     * dword  => REG_DWORD
  #     * qword  => REG_QWORD
  #     * binary => REG_BINARY
  #
  newproperty(:type) do
    @doc = <<-EOT
      The Windows data type of the registry value.
    EOT
    newvalues(:string, :array, :dword, :qword, :binary, :expand)
    defaultto :string
  end

  # @summary
  #   The data stored in the registry value.
  #
  #   Data should be specified
  #   as a string value but may be specified as a Puppet array when the
  #   type is set to `array`."
  #
  newproperty(:data, array_matching: :all) do
    @doc = <<-EOT
      The data stored in the registry value.
    EOT
    defaultto ''

    validate do |value|
      case resource[:type]
      when :array
        raise('An array registry value can not contain empty values') if value.empty?
      else
        true
      end
    end

    munge do |value|
      case resource[:type]
      when :dword
        val = begin
                Integer(value)
              rescue
                nil
              end
        raise("The data must be a valid DWORD: #{value}") unless val && (val.abs >> 32) <= 0
        val
      when :qword
        val = begin
                Integer(value)
              rescue
                nil
              end
        raise("The data must be a valid QWORD: #{value}") unless val && (val.abs >> 64) <= 0
        val
      when :binary
        if (value.respond_to?(:length) && value.length == 1) || (value.is_a?(Integer) && value <= 9)
          value = "0#{value}"
        end
        unless value =~ %r{^([a-f\d]{2} ?)*$}i
          raise("The data must be a hex encoded string of the form: '00 01 02 ...'")
        end
        # First, strip out all spaces from the string in the manfest.  Next,
        # put a space after each pair of hex digits.  Strip off the rightmost
        # space if it's present.  Finally, downcase the whole thing.  The final
        # result should be: "CaFE BEEF" => "ca fe be ef"
        value.gsub(%r{\s+}, '').gsub(%r{([0-9a-f]{2})}i) { "#{Regexp.last_match(1)} " }.rstrip.downcase
      else #:string, :expand, :array
        value
      end
    end

    def property_matches?(current, desired)
      case resource[:type]
      when :binary
        return false unless current
        current.casecmp(desired).zero?
      else
        super(current, desired)
      end
    end

    def change_to_s(currentvalue, newvalue)
      if currentvalue.respond_to? :join
        currentvalue = currentvalue.join(',')
      end
      if newvalue.respond_to? :join
        newvalue = newvalue.join(',')
      end
      super(currentvalue, newvalue)
    end
  end

  # Autorequire the nearest ancestor registry_key found in the catalog.
  autorequire(:registry_key) do
    req = []
    # This is a value path and not a key path because it's based on the path of
    # the value resource.
    path = PuppetX::Puppetlabs::Registry::RegistryValuePath.new(value(:path))
    # It is important to match against the downcase value of the path because
    # other resources are expected to alias themselves to the downcase value so
    # that we respect the case insensitive and preserving nature of Windows.
    found = path.enum_for(:ascend).find { |p| catalog.resource(:registry_key, p.to_s.downcase) }
    if found
      req << found.to_s.downcase
    end
    req
  end
end
