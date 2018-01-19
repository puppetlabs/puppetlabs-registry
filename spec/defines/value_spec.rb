require 'spec_helper'

RSpec.describe 'registry::value', :type => :define do
  let(:title) { 'RegistryTest' }
  let(:facts) {{
    'operatingsystem' => 'windows'
  }}

  context 'Given a minimal resource' do
    let(:params) {{
      :key => 'HKLM\Software\Vendor',
    }}

    it { is_expected.to compile }

    context 'On a non-windows platform' do
      let(:facts) {{
        'operatingsystem' => 'Debian'
      }}

      it { is_expected.to compile.and_raise_error(/Unsupported OS/) }
    end
  end

  context 'Given an empty key' do
    let(:params) {{
      :key => '',
    }}

    it { is_expected.to compile.and_raise_error(/parameter 'key'/) }
  end

  context 'Given an empty type' do
    let(:params) {{
      :key => 'HKLM\Software\Vendor',
      :type => '',
    }}

    it { is_expected.to compile.and_raise_error(/parameter 'type'/) }
  end
end