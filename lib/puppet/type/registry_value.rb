# frozen_string_literal: true

require 'puppet/type'
require_relative '../../puppet_x/puppetlabs/registry'

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
Puppet::Type.newtype(:registry_value) do
  @doc = <<-VALUES
    Manages registry values on Windows systems.
  VALUES
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
    @doc = <<-PATH
      The path to the registry value to manage.
    PATH
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
    @doc = <<-DATA
      The Windows data type of the registry value.
    DATA
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
    @doc = <<-DATA
      The data stored in the registry value.
    DATA

    def sensitive_value?(value)
      value.is_a?(Puppet::Pops::Types::PSensitiveType::Sensitive) ||
        (value.is_a?(Array) && value.any? { |item| sensitive_value?(item) })
    end

    def unwrap_sensitive(value)
      case value
      when Puppet::Pops::Types::PSensitiveType::Sensitive
        unwrap_sensitive(value.unwrap)
      when Array
        value.map { |item| unwrap_sensitive(item) }
      else
        value
      end
    end

    def rewrap_sensitive(original_value, munged_value)
      case original_value
      when Puppet::Pops::Types::PSensitiveType::Sensitive
        Puppet::Pops::Types::PSensitiveType::Sensitive.new(munged_value)
      when Array
        munged_value.each_with_index.map do |item, index|
          rewrap_sensitive(original_value[index], item)
        end
      else
        munged_value
      end
    end

    def redacted_value
      Puppet::Pops::Types::PSensitiveType::Sensitive.new('redacted')
    end

    def normalize_comparable(value)
      if resource[:type] != :array && value.is_a?(Array) && value.length == 1
        value.first
      else
        value
      end
    end

    # We probably shouldn't set default values for this property at all. For
    # dword and qword specifically, the legacy default value will not pass
    # validation. As such, no default value will be set for those types. At
    # least for now, other types will still have the legacy empty-string
    # default value.
    defaultto { [:dword, :qword].include?(resource[:type]) ? nil : '' }

    validate do |value|
      case resource[:type]
      when :array
        unwrapped = unwrap_sensitive(value)
        raise('An array registry value can only contain string values') unless unwrapped.is_a?(String)
        raise('An array registry value can not contain empty values') if unwrapped.empty?
      when :dword
        munged = unwrap_sensitive(munge(value))
        raise("The data must be a valid DWORD: received '#{value}'") unless munged && (munged.abs >> 32) <= 0
      when :qword
        munged = unwrap_sensitive(munge(value))
        raise("The data must be a valid QWORD: received '#{value}'") unless munged && (munged.abs >> 64) <= 0
      when :binary
        unwrapped = unwrap_sensitive(value)
        munged = unwrap_sensitive(munge(value))
        valid_binary = munged.is_a?(String) && munged.match?(%r{^([a-f\d]{2} ?)+$}i)
        valid_empty = unwrapped.is_a?(String) && unwrapped.empty?
        raise("The data must be a hex encoded string of the form: '00 01 02 ...': received '#{value}'") unless valid_binary || valid_empty
      else # :string, :expand, :array
        true
      end
    end

    munge do |value|
      unwrapped_value = unwrap_sensitive(value)

      munged = case resource[:type]
               when :dword, :qword
                 begin
                   Integer(unwrapped_value)
                 rescue StandardError
                   nil
                 end
               when :binary
                 munged = if (unwrapped_value.respond_to?(:length) && unwrapped_value.length == 1) || (unwrapped_value.is_a?(Integer) && unwrapped_value <= 9)
                            "0#{unwrapped_value}"
                          else
                            unwrapped_value
                          end

                 # First, strip out all spaces from the string in the manifest.  Next,
                 # put a space after each pair of hex digits.  Strip off the rightmost
                 # space if it's present.  Finally, downcase the whole thing.  The final
                 # result should be: "CaFE BEEF" => "ca fe be ef"
                 munged.gsub(%r{\s+}, '')
                       .gsub(%r{([0-9a-f]{2})}i) { "#{Regexp.last_match(1)} " }
                       .rstrip
                       .downcase
               else # :string, :expand, :array
                 unwrapped_value
               end

      rewrap_sensitive(value, munged)
    end

    def property_matches?(current, desired)
      if sensitive_value?(current) || sensitive_value?(desired)
        current = unwrap_sensitive(current)
        desired = unwrap_sensitive(desired)
      end

      current = normalize_comparable(current)
      desired = normalize_comparable(desired)

      case resource[:type]
      when :binary
        return false unless current

        current.casecmp(desired).zero?
      else
        super(current, desired)
      end
    end

    def change_to_s(currentvalue, newvalue)
      if sensitive_value?(currentvalue) || sensitive_value?(newvalue)
        currentvalue = redacted_value
        newvalue = redacted_value
      end

      currentvalue = currentvalue.join(',') if currentvalue.respond_to? :join
      newvalue = newvalue.join(',') if newvalue.respond_to? :join
      super(currentvalue, newvalue)
    end
  end

  validate do
    # To ensure consistent behavior, always require a value for the data
    # property. This validation can be removed if we remove the default value
    # for the data property, for all data types.
    raise ArgumentError, "No value supplied for required property 'data'" if property(:data).nil?
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
    req << found.to_s.downcase if found
    req
  end
end
