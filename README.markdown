Windows Registry Module
=======================

This module provides the types and providers necessary to manage the Windows
Registry with Puppet.

Installation
------------

The best way to install this module is with the `puppet module` subcommand or
the `puppet-module` Gem.

    puppet module install puppetlabs-registry

Make sure your `puppet agent` is configured to synchronize plugins using the
setting:

    [main]
    pluginsync = true

This is the default behavior of the Puppet Agent on Microsoft Windows
platforms.  This setting will ensure the types and providers are synchronized
and available on the agent before the configuration run takes place.


Installation from source
------------------------

If you'd like to install this module from source, please simply clone a copy
into your puppet master's `modulepath`.  Here is an example of how to do so for
Puppet Enterprise:

    $ cd /etc/puppetlabs/puppet/modules
    $ git clone git://github.com/puppetlabs/puppetlabs-registry.git registry

Examples
--------

The `registry_key` and `registry_value` types are provided by this module.

    registry_key { 'HKLM\System\CurrentControlSet\Services\Puppet':
      ensure => present,
    }
    registry_value { 'HKLM\System\CurrentControlSet\Services\Puppet\Description':
      ensure => present,
      type   => string,
      data   => "The Puppet Agent service periodically manages your configuration",
    }

Purge Values Example
--------------------

If you want to make sure only the values specified in Puppet are associated
with a particular key, you can use the `purge_values => true` parameter of the
`registry_key` resource to delete any values not explicitly managed by Puppet.
The `registry::example_purge` class shows how this is accomplished:

Make sure the `registry::example_purge` class is included in the node catalog,
then setup a registry key that contains six values:

    PS C:\> $env:FACTER_PURGE_EXAMPLE_MODE = 'setup'
    PS C:\> puppet agent --test
    notice: /Stage[main]/Registry::Purge_example/Registry_key[HKLM\Software\Vendor\Puppet Labs\Examples\KeyPurge]/ensure: created
    notice: /Stage[main]/Registry::Purge_example/Registry_value[HKLM\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value3]/ensure: created
    notice: /Stage[main]/Registry::Purge_example/Registry_value[HKLM\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value2]/ensure: created
    notice: /Stage[main]/Registry::Purge_example/Registry_key[HKLM\Software\Vendor\Puppet Labs\Examples\KeyPurge\SubKey]/ensure: created
    notice: /Stage[main]/Registry::Purge_example/Registry_value[HKLM\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value5]/ensure: created
    notice: /Stage[main]/Registry::Purge_example/Registry_value[HKLM\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value6]/ensure: created
    notice: /Stage[main]/Registry::Purge_example/Registry_value[HKLM\Software\Vendor\Puppet Labs\Examples\KeyPurge\SubKey\Value1]/ensure: created
    notice: /Stage[main]/Registry::Purge_example/Registry_value[HKLM\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value1]/ensure: created
    notice: /Stage[main]/Registry::Purge_example/Registry_value[HKLM\Software\Vendor\Puppet Labs\Examples\KeyPurge\SubKey\Value2]/ensure: created
    notice: /Stage[main]/Registry::Purge_example/Registry_value[HKLM\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value4]/ensure: created
    notice: Finished catalog run in 0.14 seconds

Switching the mode to 'purge' will cause the class to only manage three of the
six `registry_value` resources.  The other three will be purged since the
`registry_key` resource has `purge_values => true` specified in the manifest.
Notice how Value4, Value5 and Value6 are being removed.

    PS C:\> $env:FACTER_PURGE_EXAMPLE_MODE = 'purge'
    PS C:\> puppet agent --test
    notice: /Registry_value[hklm\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value4]/ensure: removed
    notice: /Registry_value[hklm\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value6]/ensure: removed
    notice: /Registry_value[hklm\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value5]/ensure: removed
    notice: /Stage[main]/Registry::Purge_example/Registry_value[HKLM\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value3]/data: data changed 'key3' to 'should not be purged'
    notice: /Stage[main]/Registry::Purge_example/Registry_value[HKLM\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value2]/data: data changed '2' to '0'
    notice: /Stage[main]/Registry::Purge_example/Registry_value[HKLM\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value1]/data: data changed '1' to '0'
    notice: Finished catalog run in 0.16 seconds

Compliance Example
------------------

In order to use the Registry module with the Compliance feature of Puppet
Enterprise, the `audit` metaparameter should be used with specific
`registry_value` resources.  An example of this is provided in the
`registry::compliance_example` class.

To get started:

 1. First, add the `registry::compliance_example` class to a node.
 2. Then, run `puppet agent --test` on the Windows node to setup a hierarchy of
    keys in `HKLM\Software\Vendor\Puppet Labs\Examples\Compliance`
 3. Switch the `registry::compliance_example` class into audit mode by setting
    a Facter fact: `$env:FACTER_REGISTRY_COMPLIANCE_EXAMPLE_MODE='audit'`.
 4. Get the new catalog containing the audit resources using: `puppet agent
    --test`.
 5. Manually change a registry value inside of `HKLM\Software\Vendor\Puppet
    Labs\Examples\Compliance`.
 6. Run `puppet inspect` and notice that Puppet has picked up the manual change
    and set it to the Puppet Enterprise Console as an inspect report.

![Registry Value Inspect Report](http://links.puppetlabs.com/screen_shot_registry_value_audit_01.png)

License
-------

[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0.html)


Contact
-------

 * Puppet Labs <support@puppetlabs.com>
 * Jeff McCune <jeff@puppetlabs.com>
 * Josh Cooper <josh@puppetlabs.com>


Support
-------

Please log tickets and issues at our [Module Issue
Tracker](http://projects.puppetlabs.com/projects/modules)

Known Issues
============

Autorequire relationships
-------------------------

The `registry_key` auto-require functionality doesn't appear to work with `->`
style relationships.  This results in a circular dependency:


    Registry_key { ensure => absent }
    registry_key { '#{keypath}\\SubKey1': }
    -> registry_key { '#{keypath}\\SubKeyToPurge': }
    -> registry_key { '#{keypath}': }

But this does not:

    registry_key { '#{keypath}\\SubKey1': }
    registry_key { '#{keypath}\\SubKeyToPurge': }
    registry_key { '#{keypath}':
      require => Registry_key['#{keypath}\\SubKeyToPurge', '#{keypath}\\SubKey1'],
    }

EOF
