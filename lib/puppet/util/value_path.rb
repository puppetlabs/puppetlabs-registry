require 'puppet/parameter'
require 'puppet/util/registry_base'

class Puppet::Util::ValuePath < Puppet::Parameter::KeyPath
  attr_reader :valuename

  def split(path)
    unless path
      raise ArgumentError, "Invalid registry value"
    end

    if path[-1, 1] == '\\' # trailing backslash implies default value
      super(path.gsub(/\\*$/, ''))
      @valuename = ''
    else
      idx = path.rindex('\\')
      raise ArgumentError, "Registry value path must contain at least one backslash." unless idx

      super(path[0, idx])
      @valuename = path[idx+1..-1] if idx > 0
    end
  end
end
