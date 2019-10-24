# @summary High level abstraction on top of registry_key and registry_value resources
#
# @note
#   This defined resource type provides a higher level of abstraction on top of
#   the registry_key and registry_value resources.  Using this defined resource
#   type, you do not need to explicitly manage the parent key for a particular
#   value.  Puppet will automatically manage the parent key for you.
#
# @param key
#   The path of key the value will placed inside.
# @param value
#   The name of the registry value to manage.  This will be copied from
#   the resource title if not specified.  The special value of
#   '(default)' may be used to manage the default value of the key.
# @param type
#   The type the registry value.  Defaults to 'string'.  See the output of
#   `puppet describe registry_value` for a list of supported types in the
#   "type" parameter.
# @param data
#   The data to place inside the registry value.
#
# Actions:
#   - Manage the parent key if not already managed.
#   - Manage the value
#
# Requires:
#   - Registry Module
#   - Stdlib Module
#
#
# @example This example will automatically manage the key.  It will also create a value named 'puppetmaster' inside this key.
#   class myapp {
#     registry::value { 'puppetmaster':
#       key => 'HKLM\Software\Vendor\PuppetLabs',
#       data => 'puppet.puppetlabs.com',
#     }
#   }
#
define registry::value (
  Pattern[/^\w+/]           $key,
  Optional[String]          $value = undef,
  Optional[Pattern[/^\w+/]] $type = 'string',
  Optional[Variant[
    String,
    Numeric,
    Array[String]
  ]]                       $data  = undef,
) {

  # ensure windows os
  if $::operatingsystem != 'windows' {
    fail("Unsupported OS ${::operatingsystem}")
  }

  $value_real = $value ? {
    undef       => $name,
    '(default)' => '',
    default     => $value,
  }

  # Resource defaults.
  Registry_key { ensure => present }
  Registry_value { ensure => present }

  if !defined(Registry_key[$key]) {
    registry_key { $key: }
  }

  # If value_real is an empty string then the default value of the key will be
  # managed.  Use a double backslash so value names with a backslash are supported
  registry_value { "${key}\\\\${value_real}":
    type => $type,
    data => $data,
  }
}
