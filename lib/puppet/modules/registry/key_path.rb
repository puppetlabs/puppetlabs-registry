require 'puppet/parameter'
require 'puppet/modules/registry/registry_base'

class Puppet::Modules::Registry::KeyPath < Puppet::Parameter
  include Puppet::Modules::Registry::RegistryBase

  attr_reader :root, :hkey, :subkey, :access

  def munge(path)
    unless captures = /^(32:)?([h|H][^\\]*)((?:\\[^\\]{1,255})*)$/.match(path)
      raise ArgumentError, "Invalid registry key: #{path}"
    end

    @access = (captures[1] and captures[1] == '32:') ? KEY_WOW64_32KEY : KEY_WOW64_64KEY

    # canonical root key symbol
    @root = case captures[2].downcase
            when /hkey_local_machine/, /hklm/
              :hklm
            when /hkey_classes_root/, /hkcr/
              :hkcr
            when /hkey_current_user/, /hkcu/,
              /hkey_users/, /hku/,
              /hkey_current_config/, /hkcc/,
              /hkey_performance_data/,
              /hkey_performance_text/,
              /hkey_performance_nlstext/,
              /hkey_dyn_data/
              raise ArgumentError, "Unsupported prefined key: #{path}"
            else
              raise ArgumentError, "Invalid registry key: #{path}"
            end

    # the hkey object for the root key
    @hkey = HKEYS[root]

    @subkey = captures[3]
    if @subkey.empty?
      canonical = root.to_s
    else
      # Leading backslash is not part of the subkey name
      @subkey.sub!(/^\\(.*)$/, '\1')
      canonical = "#{root.to_s}\\#{subkey}"
    end

    canonical
  end

  def ascend(&block)
    p = self.value

    yield p

    while idx = p.rindex('\\')
      p = p[0, idx]
      yield p
    end
  end
end
