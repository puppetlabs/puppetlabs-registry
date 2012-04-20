require 'puppet/parameter'
require 'puppet/util/registry_base'

class Puppet::Util::KeyPath < Puppet::Parameter
  include Puppet::Util::RegistryBase

  attr_reader :hkey, :subkey

  def validate(path)
    split(path.to_s)
  end

  def split(path)
    unless match = /^([^\\]*)((?:\\[^\\]{1,255})*)$/.match(path)
      raise ArgumentError, "Invalid registry key: #{path}"
    end

    @hkey =
        case match[1].downcase
        when /hkey_local_machine/, /hklm/
          HKEYS[:hklm]
        when /hkey_classes_root/, /hkcr/
          HKEYS[:hkcr]
        else
          raise ArgumentError, "Unsupported prefined key: #{path}"
        end

    # leading backslash is not part of the subkey name
    @subkey = match[2]
    @subkey = @subkey[1..-1] unless @subkey.empty?
  end

  def ascend(&block)
    s = subkey

    yield hkey, s

    while idx = s.rindex('\\')
      s = s[0, idx]
      yield hkey, s
    end
  end
end
