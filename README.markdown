Windows Registry Module
=======================

This module provides the types and providers necessary to manage the Windows
Registry with Puppet.

Installation
------------

The best way to install this module is with the `puppet module` subcommand or
the `puppet-module` Gem.  On your puppet master, execute the following command,
optionally specifying your puppet master's `modulepath` in which to install the module:

    $ puppet module install [--modulepath <path>] puppetlabs-registry

See the section [Installing Modules](http://docs.puppetlabs.com/puppet/2.7/reference/modules_installing.html#installing-modules-1) for more information.

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

The `registry::value` defined resource type provides a convenient way to manage
values and the parent key:

    registry::value { 'MyApp Setting1':
      key   => 'HKLM\Software\Vendor\PuppetLabs',
      value => setting1,
      data  => 'Hello World!'
    }

With this single resource declaration both the `registry_key` of
`HKLM\Software\Vendor\PuppetLabs` and the `registry_value` of
`HKLM\Software\Vendor\PuppetLabs\setting` will be managed.

The `registry::value` defined type only managed keys and values in the system
native architecture.  That is to say, the 32 bit keys won't be managed by this
defined type on a 64 bit OS.

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
Tracker](http://projects.puppetlabs.com/projects/modules).

Known Issues
============

Please refer to the [current list](http://projects.puppetlabs.com/projects/modules/issues?v%5Bcategory_id%5D%5B%5D=309) of known registry issues.

EOF
