require 'puppet/parameter'
require 'pathname'
# JJM WORK_AROUND
# explicitly require files without relying on $LOAD_PATH until #14073 is fixed.
# https://projects.puppetlabs.com/issues/14073 is fixed.
require Pathname.new(__FILE__).dirname
require Pathname.new(__FILE__).dirname + 'registry_base'

class Puppet::Modules::Registry::KeyPath < Puppet::Parameter
  include Puppet::Modules::Registry::RegistryBase

  attr_reader :root, :hkey, :subkey, :access

  def munge(path)
    unless captures = /^(32:)?([h|H][^\\]*)((?:\\[^\\]{1,255})*)$/.match(path)
      raise ArgumentError, "Invalid registry key: #{path}"
    end

    @access = if captures[1] == '32:'
                Puppet::Modules::Registry::KEY_WOW64_32KEY
              else
                Puppet::Modules::Registry::KEY_WOW64_64KEY
              end

    # canonical root key symbol
    @root = case captures[2].to_s.downcase
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
    @hkey = hkeys[root]

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

    while idx = p.rindex('\\')
      p = p[0, idx]
      yield p
    end
  end
end
