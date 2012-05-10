require 'pathname' # JJM WORK_AROUND #14073
require Pathname.new(__FILE__).dirname.expand_path

# This module is meant to be mixed into the registry_key type.
module Puppet::Modules::Registry::TypeKeyBase
  RegistryKeyPath   = Puppet::Modules::Registry::RegistryKeyPath
  RegistryValuePath = Puppet::Modules::Registry::RegistryValuePath
  def newpath(path)
    RegistryKeyPath.new(path)
  end
end
