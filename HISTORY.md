## 2.1.0
### Added
- Updated module for Puppet 6 ([MODULES-7832](https://tickets.puppetlabs.com/browse/MODULES-7832))

### Changed
- Update module for PDK ([MODULES-7404](https://tickets.puppetlabs.com/browse/MODULES-7404))

## [2.0.2] - 2018-08-08
### Added
- Add Windows Server 2016 and Windows 10 as supported Operating Systems ([MODULES-4271](https://tickets.puppetlabs.com/browse/MODULES-4271))

### Changed
- Convert tests to use testmode switcher ([MODULES-6744](https://tickets.puppetlabs.com/browse/MODULES-6744))

### Fixed
- Fix types to no longer use unsupported proc title patterns ([MODULES-6818](https://tickets.puppetlabs.com/browse/MODULES-6818))
- Fix acceptance tests in master-agent scenarios ([FM-6934](https://tickets.puppetlabs.com/browse/FM-6934))
- Use case insensitive search when purging ([MODULES-7534](https://tickets.puppetlabs.com/browse/MODULES-7534))

### Removed

## [2.0.1] - 2018-01-25
### Fixed
- Fix the restrictive typing introduced for the registry::value defined type to once again allow numeric values to be specified for DWORD, QWORD and arrays for REG_MULTI_SZ values ([MODULES-6528](https://tickets.puppetlabs.com/browse/MODULES-6528))

## [2.0.0] - 2018-01-24
### Added
- Add support for Puppet 5 ([MODULES-5144](https://tickets.puppetlabs.com/browse/MODULES-5144))

### Changed
- Convert beaker tests to beaker rspec tests ([MODULES-5976](https://tickets.puppetlabs.com/browse/MODULES-5976))

#### Fixed
- Ensure registry values that include a `\` as part of the name are valid and usable ([MODULES-2957](https://tickets.puppetlabs.com/browse/MODULES-2957))

### Removed
- **BREAKING:** Dropped support for Puppet 3

## [1.1.4] - 2017-03-06
### Added
- Ability to manage keys and values in `HKEY_USERS` (`hku`) ([MODULES-3865](https://tickets.puppetlabs.com/browse/MODULES-3865))

### Removed
- Remove Windows Server 2003 from supported Operating System list

#### Fixed
- Use double quotes so $key is interpolated ([FM-5236](https://tickets.puppetlabs.com/browse/FM-5236))
- Fix WOW64 Constant Definition ([MODULES-3195](https://tickets.puppetlabs.com/browse/MODULES-3195))
- Fix UNSET no longer available as a bareword ([MODULES-4331](https://tickets.puppetlabs.com/browse/MODULES-4331))

## [1.1.3] - 2015-12-08
### Added
- Support of newer PE versions.

## [1.1.2] - 2015-08-13
### Added
- Added tests to catch scenario

### Changed
- Changed byte conversion to use pack instead

### Fixed
- Fix critical bug when writing dword and qword values.
- Fix the way we write dword and qword values [MODULES-2409](https://tickets.puppet.com/browse/MODULES-2409)

## [1.1.1] - 2015-08-12 [YANKED]
### Added
- Puppet Enterprise 2015.2.0 to metadata

### Changed
- Gemfile updates
- Updated the logic used to convert to byte arrays

### Fixed
- Fixed Ruby registry writes corrupt string ([MODULES-1921](https://tickets.puppet.com/browse/MODULES-1921))
- Fixed testcases

## [1.1.0] - 2015-03-24
### Fixes
- Additional tests for purge_values
- Use wide character registry APIs
- Test Ruby Registry methods uncalled
- Introduce Ruby 2.1.5 failing tests


## [1.0.3] - 2014-08-25
### Added
- Added support for native x64 ruby and puppet 3.7

### Fixed
- Fixed issues with non-leading-zero binary values in registry keys.

## [1.0.2] - 2014-07-15
### Added
- Added the ability to uninstall and upgrade the module via the `puppet module` command

## [1.0.1] - 2014-05-20
### Fixed
- Add zero padding to binary single character inputs

## [1.0.0] - 2014-03-04
### Added
- Add license file

### Changed
- Documentation updates

## [0.1.2] - 2013-08-01
### Added
- Add geppetto project file

### Changed
- Updated README and manifest documentation
- Refactored code into PuppetX namespace
- Only manage redirected keys on 64 bit systems
- Only use /sysnative filesystem when available
- Use class accessor method instead of class instance variable

### Fixed
- Fixed unhandled exception when loading windows code on *nix

## [0.1.1] - 2012-05-21
### Fixed
- Improve error handling when writing values
- Fix management of the default value

## [0.1.0] - 2012-05-16
### Added
- Initial release
