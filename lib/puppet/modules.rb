# Open up the Puppet::Modules namespace for use by the registry module utility
# methods.  This will throw an error if there is a Puppet::Modules constant
# that is not itself a module.  (e.g. it may be a class as was the case with
# Puppet::Module and the puppet-module tool.
module Puppet
  module Modules
  end
end
