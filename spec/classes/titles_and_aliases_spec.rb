require 'spec_helper'

# The manifest used for testing, is located in spec/fixtures/test_registry/manifests/titles_and_aliases.pp

# This test is to ensure that the titles used in a manifest that appear to be unique are indeed unique and
# compile to a manifest correctly.
#
# Typically the title_patterns for the type split the string into its components however there can be cases
# where title_pattern values clash with explicitly set resource values which can then cause aliasing errors
#
# For example;
#   Cannot alias Registry_value[HKLM\Software\foo2] to ["HKLM\\Software", "Value1"] at C:/Source/puppetlabs-registry/
#   registry/spec/fixtures/modules/test_registry/manifests/titles_and_aliases.pp:7;
#   resource ["Registry_value", "HKLM\\Software", "Value1"] already declared at .../spec/fixtures/modules/test_registry/manifests/titles_and_aliases.pp:2

describe 'test_registry::titles_and_aliases' do
  it { is_expected.to compile }

  it { is_expected.to contain_registry_value('HKLM\Software\foo1') }
  it { is_expected.to contain_registry_value('HKLM\Software\foo2') }
  it { is_expected.to contain_registry_value('foo3') }
end
