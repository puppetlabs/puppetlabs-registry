require 'spec_helper'
require 'puppet/type/registry_key'
require 'puppet/type/registry_value'

RSpec.describe 'registry::value', type: :define do
  let(:title) { 'RegistryTest' }
  let(:facts) do
    {
      'operatingsystem' => 'windows',
    }
  end

  context 'Given a minimal resource' do
    let(:params) do
      {
        key: 'HKLM\Software\Vendor',
      }
    end

    it { is_expected.to compile }

    context 'On a non-windows platform' do
      let(:facts) do
        {
          'operatingsystem' => 'Debian',
        }
      end

      it { is_expected.to compile.and_raise_error(%r{Unsupported OS}) }
    end
  end

  context 'Given an empty key' do
    let(:params) do
      {
        key: '',
      }
    end

    it { is_expected.to compile.and_raise_error(%r{parameter 'key'}) }
  end

  context 'Given an empty type' do
    let(:params) do
      {
        key: 'HKLM\Software\Vendor',
        type: '',
      }
    end

    it { is_expected.to compile.and_raise_error(%r{parameter 'type'}) }
  end

  context 'Given a resource with string data' do
    let(:params) do
      {
        key: 'HKLM\Software\Vendor',
        data: 'KingKongBundy',
      }
    end

    it { is_expected.to compile }
  end

  ['dword', 'qword'].each do |type|
    context "Given a resource with #{type} numeric data" do
      let(:params) do
        {
          key: 'HKLM\Software\Vendor',
          type: type,
          data: 42,
        }
      end

      it { is_expected.to compile }
    end
  end

  context 'Given a resource with binary data' do
    let(:params) do
      {
        key: 'HKLM\Software\Vendor',
        type: 'binary',
        data: '1',
      }
    end

    it { is_expected.to compile }
  end

  ['string', 'expand'].each do |type|
    context "Given a resource with string data typed as '#{type}'" do
      let(:params) do
        {
          key: 'HKLM\Software\Vendor',
          data: 'RavishingRickRude',
          type: type,
        }
      end

      it { is_expected.to compile }
    end
  end

  context 'Given a resource with array data' do
    let(:params) do
      {
        key: 'HKLM\Software\Vendor',
        data: ['JakeTheSnake', 'AndreTheGiant'],
        type: 'array',
      }
    end

    it { is_expected.to compile }
  end
end
