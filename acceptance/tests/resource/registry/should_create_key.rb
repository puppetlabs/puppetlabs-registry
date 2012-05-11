require 'tempfile'
require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.dirname.dirname + 'lib/systest/util/registry'
# Include our utility methods in the singleton class of the test case instance.
class << self
  include Systest::Util::Registry
end

test_name "Registry Key Management"

# Generate a unique key name
keyname = "PuppetLabsTest_#{randomstring(8)}"
# This is the keypath we'll use for this entire test.  We will actually create this key and delete it.
keypath = "HKLM\\Software\\Vendor\\#{keyname}"

master_manifest_content = <<HERE
Registry_key { ensure => present}
registry_key { 'HKLM\\Software\\Vendor': }
registry_key { '#{keypath}': }
registry_key { '#{keypath}\\SubKey1': }
HERE

# Setup the master to use the modules specified in the --modules option
setup_master master_manifest_content

step "Start the master" do
  with_master_running_on(master, master_options) do
    keys_created = [
      /Registry_key\[HKLM.Software.Vendor.PuppetLabsTest\w+\].ensure: created/,
      /Registry_key\[HKLM.Software.Vendor.PuppetLabsTest\w+\\SubKey1\].ensure: created/,
    ]

    windows_agents.each do |agent|
      this_agent_args = agent_args % get_test_file_path(agent, agent_lib_dir)

      # Do the first run and make sure the key gets created.
      step "The first puppet agent run should create the key"
      run_agent_on(agent, this_agent_args, :acceptable_exit_codes => agent_exit_codes) do
        keys_created.each do |key_re|
          assert_match(key_re, result.stdout,
                       "Expected #{key_re.inspect} to match the output. (First Run)")
        end
        assert_no_match(/err:/, result.stdout, "Expected no error messages.")
      end

      step "The second puppet agent run should not create the key"
      # Do a second run and make sure the key isn't created a second time.
      run_agent_on(agent, this_agent_args, :acceptable_exit_codes => agent_exit_codes) do
        keys_created.each do |key_re|
          assert_no_match(key_re, result.stdout,
                       "Expected #{key_re.inspect} NOT to match the output. (First Run)")
        end
        assert_no_match(/err:/, result.stdout, "Expected no error messages.")
      end
    end
  end
end

clean_up
