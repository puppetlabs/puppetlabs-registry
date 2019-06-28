# registry
[![Build Status](https://travis-ci.org/puppetlabs/puppetlabs-registry.png?branch=master)](https://travis-ci.org/puppetlabs/puppetlabs-registry)

#### Table of Contents

1. [Overview - What is the registry module?](#overview)
2. [Module Description - What registry does and why it is useful](#module-description)
3. [Setup - The basics of getting started with registry](#setup)
    * [Beginning with registry](#beginning-with-registry)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference](#reference)
6. [Limitations](#limitations)
7. [Development - Guide for contributing to registry](#development)

## Overview

This module supplies the types and providers you'll need to manage the Registry on your Windows nodes.

## Module Description

The Registry is a hierarchical database built into Microsoft Windows. It stores settings and other information for the operating system and a wide range of applications. This module lets Puppet manage individual Registry keys and values, and provides a simplified way to manage Windows services.

## Setup

This module must be installed on your Puppet master. We've tested it with Puppet agents running on Windows Server 2008 R2, 2012, and 2012 R2.

### Beginning with registry

Use the `registry_key` type to manage a single registry key:

``` puppet
registry_key { 'HKLM\System\CurrentControlSet\Services\Puppet':
    ensure => present,
}
```

## Usage

The registry module works mainly through two types: `registry_key` and `registry_value`. These types combine to let you specify a Registry container and its intended contents.

### Manage a single Registry value

``` puppet
registry_value { 'HKLM\System\CurrentControlSet\Services\Puppet\Description':
  ensure => present,
  type   => string,
  data   => "The Puppet Agent service periodically manages your configuration",
}
```

### Manage a single Registry value with a backslash in the value name

``` puppet
registry_value { 'HKLM\System\CurrentControlSet\Services\Puppet\\\ValueWithA\Backslash':
  ensure     => present,
  type       => string,
  data       => "The Puppet Agent service periodically manages your configuration",
}
```

### Manage a single Registry value with a different resource title

``` puppet
registry_value { 'PuppetDescription':
  path       => 'HKLM\System\CurrentControlSet\Services\Puppet\Description',
  ensure     => present,
  type       => string,
  data       => "The Puppet Agent service periodically manages your configuration",
}
```

### Manage a Registry value and its parent key in one declaration

``` puppet
class myapp {
  registry::value { 'puppetmaster':
    key  => 'HKLM\Software\Vendor\PuppetLabs',
    data => 'puppet.puppet.com',
  }
}
```

Puppet looks up the key 'HKLM\Software\Vendor\PuppetLabs' and makes sure it contains a value named 'puppetmaster' containing the string 'puppet.puppet.com'.

### Set the default value for a key

``` puppet
registry::value { 'Setting0':
  key   => 'HKLM\System\CurrentControlSet\Services\Puppet',
  value => '(default)',
  data  => "Hello World!",
}
```

You can still add values in a string (or array) beyond the default, but you can only set one default value per key.


### Purge existing values

By default, if a key includes additional values besides the ones you specify through this module, Puppet leaves those extra values in place. To change that, use the `purge_values => true` parameter of the `registry_key` resource. **Enabling this feature deletes any values in the key that are not managed by Puppet.**

The `registry::purge_example` class provides a quick and easy way to see a demonstration of how this works. This example class has two modes of operation determined by the Facter fact `PURGE_EXAMPLE_MODE`: 'setup' and 'purge'.

To run the demonstration, make sure the `registry::purge_example` class is included in your node catalog, then set an environment variable in PowerShell. This sets up a Registry key that contains six values.

``` powershell
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
```

Switching the mode to 'purge' causes the class to only manage three of the six `registry_value` resources. The other three are purged because they are not specifically declared in the manifest.
Notice how `Value4`, `Value5` and `Value6` are being removed.

``` powershell
PS C:\> $env:FACTER_PURGE_EXAMPLE_MODE = 'purge'
PS C:\> puppet agent --test

notice: /Registry_value[hklm\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value4]/ensure: removed
notice: /Registry_value[hklm\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value6]/ensure: removed
notice: /Registry_value[hklm\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value5]/ensure: removed
notice: /Stage[main]/Registry::Purge_example/Registry_value[HKLM\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value3]/data: data changed 'key3' to 'should not be purged'
notice: /Stage[main]/Registry::Purge_example/Registry_value[HKLM\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value2]/data: data changed '2' to '0'
notice: /Stage[main]/Registry::Purge_example/Registry_value[HKLM\Software\Vendor\Puppet Labs\Examples\KeyPurge\Value1]/data: data changed '1' to '0'
notice: Finished catalog run in 0.16 seconds
```

### Manage Windows services

The `registry::service` define manages entries in the Microsoft service control framework by automatically manipulating values in the key `HKLM\System\CurrentControlSet\Services\$name\`.

This is an alternative approach to using INSTSRV.EXE [1](http://support.microsoft.com/kb/137890).

``` puppet
registry::service { puppet:
  ensure       => present,
  display_name => "Puppet Agent",
  description  => "Periodically fetches and applies configurations from a Puppet master server.",
  command      => 'C:\PuppetLabs\Puppet\service\daemon.bat',
}
```

## Reference
For information on the classes and types, see the [REFERENCE.md](https://github.com/puppetlabs/puppetlabs-registry/blob/master/REFERENCE.md)

## Limitations

* Keys within `HKEY_LOCAL_MACHINE` (`hklm`), `HKEY_CLASSES_ROOT` (`hkcr`) or `HKEY_USERS` (`hku`) are supported. Other predefined root keys (e.g., `HKEY_CURRENT_USER`) are not currently supported.
* Puppet doesn't recursively delete Registry keys.

Please report any issues through our [Module Issue Tracker](https://tickets.puppet.com/browse/MODULES).

## Development

Puppet Inc modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. We can't access the huge number of platforms and myriad of hardware, software, and deployment configurations that Puppet is intended to serve.

We want to keep it as easy as possible to contribute changes so that our modules work in your environment. There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

If you would like to contribute to this module, please follow the rules in the [CONTRIBUTING.md](https://github.com/puppetlabs/puppetlabs-registry/blob/master/CONTRIBUTING.md). For more information, see our [module contribution guide.](https://puppet.com/docs/puppet/latest/contributing.html)

### Contributors

To see who's already involved, see the [list of contributors.](https://github.com/puppetlabs/puppetlabs-registry/graphs/contributors)
