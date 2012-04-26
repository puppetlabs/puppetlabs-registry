require 'pathname'
# JJM WORK_AROUND
# explicitly require files without relying on $LOAD_PATH until #14073 is fixed.
# https://projects.puppetlabs.com/issues/14073 is fixed.
require Pathname.new(__FILE__).dirname.expand_path + 'key_path'
require 'puppet/parameter'

class Puppet::Modules::Registry::ValuePath < Puppet::Modules::Registry::KeyPath
  attr_reader :valuename

  def munge(path)
    raise ArgumentError, "Invalid registry value" unless path

    if path[-1, 1] == '\\' # trailing backslash implies default value
      super(path.gsub(/\\*$/, ''))
      @valuename = ''
    else
      idx = path.rindex('\\')
      raise ArgumentError, "Registry value path must contain at least one backslash." unless idx

      super(path[0, idx])
      @valuename = path[idx+1..-1] if idx > 0
    end

    canonical = subkey.empty? ?  "#{root}\\#{valuename}" : "#{root}\\#{subkey}\\#{valuename}"
    canonical
  end
end
