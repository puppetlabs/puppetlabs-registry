require 'pathname'
require 'spec_helper_acceptance'

describe 'registry::value defined type' do

# Generate a unique key name
  keyname = "PuppetLabsTest_MixedCase_#{random_string(8)}"
# This is the keypath we'll use for this entire test.  We will actually create this key and delete it.
  vendor_path = "HKLM\\Software\\Vendor"
  keypath = "#{vendor_path}\\#{keyname}"

  manifest = <<HERE
    registry_key { '#{vendor_path}': ensure => present }

    registry::value { 'Setting1':
      key   => '#{keypath}',
      value => 'Setting1',
      data  => "fact_phase=${fact_phase}",
    }
    registry::value { 'Setting2':
      key   => '#{keypath}',
      data  => "fact_phase=${fact_phase}",
    }
    registry::value { 'Setting3':
      key   => '#{keypath}',
      value => 'Setting3',
      data  => "fact_phase=${fact_phase}",
    }
    registry::value { 'Setting0':
      key   => '#{keypath}',
      value => '(default)',
      data  => "fact_phase=${fact_phase}",
    }
HERE

  context 'Start testing should_have_defined_type' do
    # A set of keys we expect Puppet to create
    phase1_resources_created = [
        /Registry_key\[HKLM.Software.Vendor.PuppetLabsTest\w+\].ensure: created/,
        /Registry_value\[HKLM\\Software\\Vendor\\PuppetLabsTest\w+\\\\\].ensure: created/,
        /Registry_value\[HKLM\\Software\\Vendor\\PuppetLabsTest\w+\\\\Setting1\].ensure: created/,
        /Registry_value\[HKLM\\Software\\Vendor\\PuppetLabsTest\w+\\\\Setting2\].ensure: created/,
        /Registry_value\[HKLM\\Software\\Vendor\\PuppetLabsTest\w+\\\\Setting3\].ensure: created/,
    ]

    phase2_resources_changed = [
        /Registry_value\[HKLM\\Software\\Vendor\\PuppetLabsTest\w+\\\\\].data: data changed 'fact_phase=1' to 'fact_phase=2'/,
        /Registry_value\[HKLM\\Software\\Vendor\\PuppetLabsTest\w+\\\\Setting1\].data: data changed 'fact_phase=1' to 'fact_phase=2'/,
        /Registry_value\[HKLM\\Software\\Vendor\\PuppetLabsTest\w+\\\\Setting2\].data: data changed 'fact_phase=1' to 'fact_phase=2'/,
        /Registry_value\[HKLM\\Software\\Vendor\\PuppetLabsTest\w+\\\\Setting3\].data: data changed 'fact_phase=1' to 'fact_phase=2'/,
    ]
    windows_agents.each do |agent|
      it 'Phase 1.a - Create some values' do
        execute_manifest_on agent, manifest, get_apply_opts({'FACTER_FACT_PHASE' => '1'}) do
          phase1_resources_created.each do |val_re|
            assert_match(val_re, @result.stdout, "Expected output to contain #{val_re.inspect}.")
          end
          assert_no_match(/err:/, @result.stdout, 'Expected no error messages.')
        end
      end

      it 'Phase 1.b - Make sure Puppet is idempotent' do
        execute_manifest_on agent, manifest, get_apply_opts({'FACTER_FACT_PHASE' => '1'}) do
          phase1_resources_created.each do |val_re|
            assert_no_match(val_re, @result.stdout, "Expected output not to contain #{val_re.inspect}.")
          end
          assert_no_match(/err:/, @result.stdout, 'Expected no error messages.')
        end
      end

      it 'Phase 2.a - Change some values' do
        execute_manifest_on agent, manifest, get_apply_opts({'FACTER_FACT_PHASE' => '2'}) do
          phase2_resources_changed.each do |val_re|
            assert_match(val_re, @result.stdout, "Expected output to contain #{val_re.inspect}.")
          end
          assert_no_match(/err:/, @result.stdout, 'Expected no error messages.')
        end
      end

      it 'Phase 2.b - Make sure Puppet is idempotent' do
        execute_manifest_on agent, manifest, get_apply_opts({'FACTER_FACT_PHASE' => '2'}) do
          (phase1_resources_created + phase2_resources_changed).each do |val_re|
            assert_no_match(val_re, @result.stdout, "Expected output not to contain #{val_re.inspect}.")
          end
          assert_no_match(/err:/, @result.stdout, 'Expected no error messages.')
        end
      end
    end
  end
end
