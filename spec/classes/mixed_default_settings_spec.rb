require 'spec_helper'

# The manifest used for testing, is located in spec/fixtures/mixed_default_settings/manifests/init.pp

# This test is to ensure that the way of setting default values (trailing slash) compiles correctly
# when there is a similar looking path in the manifest. It mixes default and non-default value_names in the same manifest
#
# This manifest attempts to manage two registry values
#
# + HKLM
#     + Software
#         - foo                  <-- This is a value called 'foo' in the 'HKLM\Sofware' key.
#         |                          This is the 'hklm\Software\foo' resource
#         |
#         + foo
#             + (default value)  <-- This is the default value for a key called 'HKLM\Software\foo'.
#                                    This is the 'hklm\Software\foo\\' resource
#

describe 'mixed_default_settings' do
  it { is_expected.to compile }

  it { is_expected.to contain_registry_value('hklm\Software\foo\\') }
  it { is_expected.to contain_registry_value('hklm\Software\foo') }
end
