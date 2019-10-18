require 'spec_helper_acceptance'

describe 'Registry Management' do
  before(:all) do
    # use this unique keyname and keypath for all tests
    @keyname = "PuppetLabsTest_#{random_string(8)}"
  end

  let(:arch_prefix) { (host_inventory['facter']['architecture'] == 'x64') ? '32:' : '' }
  let(:keypath) { "HKLM\\Software\\Vendor\\#{@keyname}" } # rubocop:disable RSpec/InstanceVariable

  let(:create) do
    <<-CREATE
      # use a different case here, to exercise the case-conversion codepaths
      registry_key { 'HKLM\\Software\\VENDOR': ensure => present }

      registry_key { '#{keypath}': ensure => present }
      registry_key { '#{keypath}\\SubKey1': ensure => present }

      registry_key   { '#{keypath}\\SubKeyToPurge': ensure => present }

      registry_value { '#{keypath}\\SubKeyToPurge\\Value1': data => 'Test Data1' }
      # use a different case here, to exercise the case-conversion codepaths
      registry_value { '#{keypath}\\SUBKEYTOPURGE\\Value2': data => 'Test Data2' }
      registry_value { '#{keypath}\\SubKeyToPurge\\Value3': data => 'Test Data3' }

      registry_value { '#{keypath}\\SubKey1\\\\':
        data => "Some Data",
      }

      registry_value { '#{keypath}\\SubKey1\\ValueArray':
        type => array,
        data => [ "content", "array element" ],
      }

      registry_value { '#{keypath}\\SubKey1\\ValueExpand':
        type => expand,
        data => "%SystemRoot% - a REG_EXPAND_SZ value",
      }

      registry_value { '#{keypath}\\SubKey1\\ValueDword':
        type => dword,
        data => 42,
      }

      registry_value { '#{keypath}\\SubKey1\\ValueQword':
        type => qword,
        data => 99,
      }

      registry_value { '#{keypath}\\SubKey1\\ValueBinary':
        type => binary,
        data => "DE AD BE EF CA FE"
      }

      # 32bit and registry::value testing
      registry::value { 'some_value':
        key  => '32:HKLM\\Software\\VENDOR\\PuppetLabs_32bits',
        data => "32bit string",
      }
CREATE
  end

  let(:update) do
    <<-UPDATE
      registry_key { '#{keypath}\\SubKeyToPurge':
        ensure => present,
        purge_values => true,
      }

      registry_value { '#{keypath}\\SubKey1\\\\':
        data => "Some Updated Data",
      }

      registry_value { '#{keypath}\\SubKey1\\ValueArray':
        type => array,
        data => [ "content", "array element", "additional element" ],
      }

      registry_value { '#{keypath}\\SubKey1\\ValueExpand':
        type => expand,
        data => "%SystemRoot% - an updated REG_EXPAND_SZ value",
      }

      registry_value { '#{keypath}\\SubKey1\\ValueDword':
        type => dword,
        data => 17,
      }

      registry_value { '#{keypath}\\SubKey1\\ValueQword':
        type => qword,
        data => 53,
      }

      registry_value { '#{keypath}\\SubKey1\\ValueBinary':
        type => binary,
        data => "AB CD EF 16 32"
      }

      # 32bit and registry::value testing
      registry::value { 'some_value':
        key  => '32:HKLM\\Software\\VENDOR\\PuppetLabs_32bits',
        data => "updated 32bit string",
      }
UPDATE
  end

  let(:delete) do
    <<-DELETE
      Registry_key { ensure => absent }

      # These have relationships because autorequire break things when
      # ensure is absent.  REVISIT: Make this not a requirement.
      # REVISIT: This appears to work with explicit relationships but not with ->
      # notation.
      registry_key { '#{keypath}\\SubKey1': }
      registry_key { '#{keypath}\\SubKeyToPurge': }
      registry_key { '#{keypath}':
        require => Registry_key['#{keypath}\\SubKeyToPurge', '#{keypath}\\SubKey1'],
      }

      registry_value { [
        '#{keypath}\\SubKey1\\\\',
        '#{keypath}\\SubKey1\\ValueArray',
        '#{keypath}\\SubKey1\\ValueExpand',
        '#{keypath}\\SubKey1\\ValueDword',
        '#{keypath}\\SubKey1\\ValueQword',
        '#{keypath}\\SubKey1\\ValueBinary',
      ]:
        ensure => absent
      }

      # 32bit and registry::value testing
      # registry::value { 'some_value':
      #   key    => '32:HKLM\\Software\\VENDOR\\PuppetLabs_32bits',
      #   ensure => absent,
      # }
      registry_value { '32:HKLM\\Software\\VENDOR\\PuppetLabs_32bits\\\\some_value':
        ensure => absent,
      }
DELETE
  end

  it 'creates registry entries' do
    idempotent_apply(create)
  end

  it 'update registry entries' do
    idempotent_apply(update)
  end

  it 'deletes registry entries' do
    idempotent_apply(delete)
  end
end
