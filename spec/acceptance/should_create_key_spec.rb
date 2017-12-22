require 'tempfile'
require 'pathname'
require 'spec_helper_acceptance'

describe 'Registry Key Management' do

  # Setup the master to use the modules specified in the --modules option

  context 'registry test key variable setup' do

    # Generate a unique key name
    keyname = "PuppetLabsTest_#{random_string(8)}"
    # This is the keypath we'll use for this entire test.  We will actually create this key and delete it.
    keypath = "HKLM\\Software\\Vendor\\#{keyname}"

    # Setup keys to purge
    phase1 = <<PHASE1
      registry_key { 'HKLM\\Software\\Vendor': ensure => present }
      Registry_key { ensure => present }
      Registry_value { ensure => present, data => 'Puppet Default Data' }

      registry_key { '#{keypath}': }
      registry_key { '#{keypath}\\SubKey1': }

      if $architecture == 'x64' {
        registry_key { '32:#{keypath}': }
        registry_key { '32:#{keypath}\\SubKey1': }
      }

      registry_key   { '#{keypath}\\SubKeyToPurge': }
      registry_value { '#{keypath}\\SubKeyToPurge\\Value1': }
      registry_value { '#{keypath}\\SubKeyToPurge\\Value2': }
      registry_value { '#{keypath}\\SubKeyToPurge\\Value3': }

      if $architecture == 'x64' {
        registry_key   { '32:#{keypath}\\SubKeyToPurge': }
        registry_value { '32:#{keypath}\\SubKeyToPurge\\Value1': }
        registry_value { '32:#{keypath}\\SubKeyToPurge\\Value2': }
        registry_value { '32:#{keypath}\\SubKeyToPurge\\Value3': }
      }
PHASE1

    # Purge the keys in a subsequent run
    phase2 = <<PHASE2
      registry_key { 'HKLM\\Software\\Vendor': ensure => present }
      Registry_key { ensure => present, purge_values => true }

      registry_key { '#{keypath}\\SubKeyToPurge': }
      if $architecture == 'x64' {
        registry_key { '32:#{keypath}\\SubKeyToPurge': }
      }
PHASE2

    # Delete our keys
    phase3 = <<PHASE3
      registry_key { 'HKLM\\Software\\Vendor': ensure => present }
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

      if $architecture == 'x64' {
        registry_key { '32:#{keypath}\\SubKey1': }
        registry_key { '32:#{keypath}\\SubKeyToPurge': }
        registry_key { '32:#{keypath}':
          require => Registry_key['32:#{keypath}\\SubKeyToPurge', '32:#{keypath}\\SubKey1'],
        }
      }
PHASE3

    # setup_master master_manifest_content
    # with_puppet_running_on master, :__commandline_args__ => master_options do
    # A set of keys we expect Puppet to create
    keys_created_native = [
        /Registry_key\[HKLM.Software.Vendor.PuppetLabsTest\w+\].ensure: created/,
        /Registry_key\[HKLM.Software.Vendor.PuppetLabsTest\w+\\SubKey1\].ensure: created/
    ]

    keys_created_wow = [
        /Registry_key\[32:HKLM.Software.Vendor.PuppetLabsTest\w+\].ensure: created/,
        /Registry_key\[32:HKLM.Software.Vendor.PuppetLabsTest\w+\\SubKey1\].ensure: created/
    ]

    # A set of regular expression of values to be purged in phase 2.
    values_purged_native = [
        /Registry_value\[Generated_hklm\\Software\\Vendor\\PuppetLabsTest\w+.SubKeyToPurge\\Value1_[\w-]+\].ensure: removed/,
        /Registry_value\[Generated_hklm\\Software\\Vendor\\PuppetLabsTest\w+.SubKeyToPurge\\Value2_[\w-]+\].ensure: removed/,
        /Registry_value\[Generated_hklm\\Software\\Vendor\\PuppetLabsTest\w+.SubKeyToPurge\\Value3_[\w-]+\].ensure: removed/
    ]

    values_purged_wow = [
        /Registry_value\[Generated_32:hklm\\Software\\Vendor\\PuppetLabsTest\w+.SubKeyToPurge\\Value1_[\w-]+\].ensure: removed/,
        /Registry_value\[Generated_32:hklm\\Software\\Vendor\\PuppetLabsTest\w+.SubKeyToPurge\\Value2_[\w-]+\].ensure: removed/,
        /Registry_value\[Generated_32:hklm\\Software\\Vendor\\PuppetLabsTest\w+.SubKeyToPurge\\Value3_[\w-]+\].ensure: removed/,
    ]

    windows_agents.each do |agent|
      keys_created = keys_created_native + (is_x64(agent) ? keys_created_wow : [])
      values_purged = values_purged_native + (is_x64(agent) ? values_purged_wow : [])

      it 'Registry - Phase 1.a - Create some keys' do
        apply_manifest_on(agent, phase1, get_apply_opts) do
          keys_created.each do |key_re|
            assert_match(key_re, @result.stdout, "Expected #{key_re.inspect} to match the output. (First Run)")
          end
          assert_no_match(/err:/, @result.stdout, 'Expected no error messages.')
        end
      end

      it 'Registry - Phase 1.b - Make sure Puppet is idempotent' do
        # Do a second run and make sure the key isn't created a second time.
         apply_manifest_on(agent, phase1, get_apply_opts) do
          keys_created.each do |key_re|
            assert_no_match(key_re, @result.stdout,
                            "Expected #{key_re.inspect} NOT to match the output. (First Run)")
          end
          assert_no_match(/err:/, @result.stdout, 'Expected no error messages.')
        end
      end

      it 'Registry - Phase 2 - Make sure purge_values works' do
        apply_manifest_on(agent, phase2, get_apply_opts({'FACTER_FACT_PHASE' => '2'})) do
          values_purged.each do |val_re|
            assert_match(val_re, @result.stdout, "Expected output to contain #{val_re.inspect}.")
          end
          assert_no_match(/err:/, @result.stdout, 'Expected no error messages.')
        end
      end

      it 'Registry - Phase 3 - Should clean up' do
        apply_manifest_on(agent, phase3, get_apply_opts({'FACTER_FACT_PHASE' => '3'})) do
          assert_no_match(/err:/, @result.stdout, 'Expected no error messages.')
        end
      end
    end
  end
end

