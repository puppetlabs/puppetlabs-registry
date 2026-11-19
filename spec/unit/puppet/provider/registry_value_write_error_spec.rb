# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/registry_value'

describe Puppet::Type.type(:registry_value).provider(:registry) do
  let(:type) { Puppet::Type.type(:registry_value) }
  let(:path) { 'hklm\SOFTWARE\Puppet Labs\DoesNotNeedToExist\SomeValue' }
  let(:reg_value) { type.new(path:, type: :dword, data: 1, provider: described_class.name) }
  let(:fake_reg) { instance_double(Win32::Registry) }
  let(:fake_hive) { instance_double(Win32::Registry) }

  before(:each) do
    skip('Not on Windows platform') unless Puppet.features.microsoft_windows?

    allow(fake_hive).to receive(:open).and_yield(fake_reg)
    allow(reg_value.provider).to receive(:hive).and_return(fake_hive)
  end

  context 'when write_value encounters a Win32::Registry::Error' do
    context 'when the parent key does not exist (error code 2)' do
      before(:each) do
        allow(reg_value.provider).to receive(:write).and_raise(Win32::Registry::Error, 2)
      end

      it 'raises a Puppet::Error with the intended message instead of a NameError' do
        expect { reg_value.provider.create }.to raise_error(Puppet::Error, %r{Cannot write to the registry\. The parent key does not exist\.})
      end
    end

    context 'when an unexpected Win32 error occurs' do
      before(:each) do
        allow(reg_value.provider).to receive(:write).and_raise(Win32::Registry::Error, 5)
      end

      it 'raises a Puppet::Error with the unexpected exception message instead of a NameError' do
        expect { reg_value.provider.create }.to raise_error(Puppet::Error, %r{Unexpected exception from Win32 API.*ERROR CODE: 5})
      end
    end
  end
end
