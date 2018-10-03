require 'spec_helper'
require 'puppet/type/registry_key'
require 'puppet/type/registry_value'

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

  context 'Given a resource with string data' do
    let(:params) {{
       :key  => 'HKLM\Software\Vendor',
       :data => 'KingKongBundy'
    }}

    it { is_expected.to compile }
  end

  ['dword', 'qword'].each do |type|
    context "Given a resource with #{type} numeric data" do
      let(:params) {{
         :key  => 'HKLM\Software\Vendor',
         :type => type,
         :data => 42,
      }}

      it { is_expected.to compile }
    end
  end

  context 'Given a resource with binary data' do
    let(:params) {{
       :key  => 'HKLM\Software\Vendor',
       :type => 'binary',
       :data => '1'
    }}

    it { is_expected.to compile }
  end

  ['string', 'expand'].each do |type|
    context "Given a resource with string data typed as '#{type}'" do
      let(:params) {{
        :key  => 'HKLM\Software\Vendor',
        :data => 'RavishingRickRude',
        :type => type,
      }}

      it { is_expected.to compile }
    end
  end

  context 'Given a resource with array data' do
    let(:params) {{
       :key  => 'HKLM\Software\Vendor',
       :data => ['JakeTheSnake', 'AndreTheGiant'],
       :type => 'array',
    }}

    it { is_expected.to compile }
  end
end
