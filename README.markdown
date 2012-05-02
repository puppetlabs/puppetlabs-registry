Windows Registry Module
=======================

This module provides the types and providers necessary to manage the Windows
Registry with Puppet.

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
