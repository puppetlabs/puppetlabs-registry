require 'spec_helper'
require 'puppet/type/registry_key'
require 'puppet/type/registry_value'

RSpec.describe 'registry::value', type: :define do
  let(:title) { 'value_name' }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      context 'with an empty key' do
        let(:params) { { key: '' } }

        it { is_expected.to compile.and_raise_error(%r{parameter 'key'}) }
      end

      context 'with a key specified' do
        let(:params) { { key: 'HKLM\Software\Vendor' } }

        it { is_expected.to compile }
        it {
          is_expected.to contain_registry_key('HKLM\Software\Vendor')
            .with_ensure('present')
        }
        it {
          is_expected.to contain_registry_value('HKLM\Software\Vendor\\\\value_name')
            .with(
              ensure: 'present',
              type: 'string',
              data: nil,
            )
        }

        context 'with an empty type' do
          let(:params) { super().merge(type: '') }

          it { is_expected.to compile.and_raise_error(%r{parameter 'type'}) }
        end

        context 'with untyped string data' do
          let(:params) { super().merge(data: 'some string data') }

          it { is_expected.to compile }
          it {
            is_expected.to contain_registry_value('HKLM\Software\Vendor\\\\value_name')
              .with(
                ensure: 'present',
                type: 'string',
                data: 'some string data',
              )
          }
        end

        ['dword', 'qword'].each do |type|
          context "with #{type} numeric data" do
            let(:params) { super().merge(type: type, data: 42) }

            it { is_expected.to compile }
            it {
              is_expected.to contain_registry_value('HKLM\Software\Vendor\\\\value_name')
                .with(
                  ensure: 'present',
                  type: type,
                  data: 42,
                )
            }
          end
        end

        context 'with binary data' do
          let(:params) { super().merge(type: 'binary', data: '1') }

          it { is_expected.to compile }
          it {
            is_expected.to contain_registry_value('HKLM\Software\Vendor\\\\value_name')
              .with(
                ensure: 'present',
                type: 'binary',
                data: '1',
              )
          }
        end

        ['string', 'expand'].each do |type|
          context "with string data typed as '#{type}'" do
            let(:params) { super().merge(type: type, data: 'some typed string data') }

            it { is_expected.to compile }
            it {
              is_expected.to contain_registry_value('HKLM\Software\Vendor\\\\value_name')
                .with(
                  ensure: 'present',
                  type: type,
                  data: 'some typed string data',
                )
            }
          end
        end

        context 'with array data' do
          let(:params) { super().merge(type: 'array', data: ['JakeTheSnake', 'AndreTheGiant']) }

          it { is_expected.to compile }
          it {
            is_expected.to contain_registry_value('HKLM\Software\Vendor\\\\value_name')
              .with(
                ensure: 'present',
                type: 'array',
                data: ['JakeTheSnake', 'AndreTheGiant'],
              )
          }
        end

        context 'with an empty value name' do
          let(:params) { super().merge(value: '(default)') }

          it { is_expected.to compile }
          it {
            is_expected.to contain_registry_value('HKLM\Software\Vendor\\\\')
              .with_ensure('present')
          }
        end

        context 'with a value name override' do
          let(:params) { super().merge(value: 'other_name') }

          it { is_expected.to compile }
          it {
            is_expected.to contain_registry_value('HKLM\Software\Vendor\\\\other_name')
              .with_ensure('present')
          }
        end
      end
    end
  end

  context 'On a non-windows platform' do
    let(:params) do
      {
        key: 'foo',
      }
    end
    let(:facts) do
      {
        'operatingsystem' => 'bar',
      }
    end

    it { is_expected.to compile.and_raise_error(%r{Unsupported OS bar}) }
  end
end
