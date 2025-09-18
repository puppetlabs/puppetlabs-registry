# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/registry_value'

describe Puppet::Type.type(:registry_value) do
  let(:catalog) { Puppet::Resource::Catalog.new }

  [:ensure, :type, :data].each do |property|
    it "has a #{property} property" do
      expect(described_class.attrclass(property).ancestors.should(be_include(Puppet::Property)))
    end

    it "has documentation for its #{property} property" do
      expect(described_class.attrclass(property).doc.should(be_instance_of(String)))
    end
  end

  describe 'path parameter' do
    it 'has a path parameter' do
      expect(Puppet::Type.type(:registry_value).attrtype(:path).should == :param)
    end

    # rubocop:disable RSpec/RepeatedExample
    ['hklm\\propname', 'hklm\\software\\propname'].each do |path|
      it "accepts #{path}" do
        expect(described_class.new(path:, catalog:))
      end
    end

    ['hklm\\', 'hklm\\software\\', 'hklm\\software\\vendor\\'].each do |path|
      it "accepts the unnamed (default) value: #{path}" do
        expect(described_class.new(path:, catalog:))
      end
    end
    # rubocop:enable RSpec/RepeatedExample

    it 'strips trailling slashes from unnamed values' do
      value = described_class.new(path: 'hklm\\software\\\\', catalog:)

      expect(value[:path]).to eq('hklm\\software\\')
    end

    ['HKEY_DYN_DATA\\', 'HKEY_PERFORMANCE_DATA\\name'].each do |path|
      it "rejects #{path} as unsupported" do
        expect { described_class.new(path:, catalog:) }.to raise_error(Puppet::Error, %r{Unsupported})
      end
    end

    ['hklm', 'hkcr', 'unknown\\name', 'unknown\\subkey\\name'].each do |path|
      it "rejects #{path} as invalid" do
        expect { described_class.new(path:, catalog:) }.to raise_error(Puppet::Error, %r{Invalid registry key})
      end
    end

    ['HKLM\\name', 'HKEY_LOCAL_MACHINE\\name', 'hklm\\name'].each do |root|
      it "canonicalizes root key #{root}" do
        value = described_class.new(path: root, catalog:)
        expect(value[:path].should == 'hklm\name')
      end
    end

    ['HKLM\\Software\\\\nam\\e', 'HKEY_LOCAL_MACHINE\\Software\\\\nam\\e', 'hklm\\Software\\\\nam\\e'].each do |root|
      it "uses a double backslash when canonicalizing value names with a backslash #{root}" do
        value = described_class.new(path: root, catalog:)
        expect(value[:path].should == 'hklm\Software\\\\nam\e')
      end
    end

    {
      'HKLM\\Software\\\\Middle\\\\Slashes' => 'hklm\\Software\\\\Middle\\\\Slashes',
      'HKLM\\Software\\\\\\\\LeadingSlashes' => 'hklm\\Software\\\\\\\\LeadingSlashes',
      'HKLM\\Software\\\\TrailingSlashes\\' => 'hklm\\Software\\\\TrailingSlashes\\',
      'HKLM\\Software\\\\\\' => 'hklm\\Software\\\\\\' # A value name of backslash
    }.each do |testcase, expected_value|
      it "uses a double backslash as a delimeter between path and value for title #{testcase}" do
        value = described_class.new(path: testcase, catalog:)
        expect(value[:path].should == expected_value)
      end
    end

    it 'should validate the length of the value name'
    it 'should validate the length of the value data'
    it 'should be case-preserving'
    it 'should be case-insensitive'
    it 'supports 32-bit values' do
      expect(_value = described_class.new(path: '32:hklm\software\foo', catalog:))
    end
  end

  describe '#autorequire' do
    let(:instance) { described_class.new(title: subject_title, catalog:) }

    [
      {
        context: 'with a non-default value_name',
        reg_value_title: 'hklm\software\foo\bar',
        expected_reg_key_title: 'hklm\Software\foo'
      },
      {
        context: 'with a mixed case path and value_name',
        reg_value_title: 'hkLm\soFtwarE\fOo\Bar',
        expected_reg_key_title: 'hklm\Software\foo'
      },
      {
        context: 'with a default value_name',
        reg_value_title: 'hklm\software\foo\bar\\',
        expected_reg_key_title: 'hklm\Software\foo\bar'
      },
      {
        context: 'with a value whose parent key is not managed but does have an ancestor key in the catalog',
        reg_value_title: 'hklm\software\foo\bar\baz\alice',
        expected_reg_key_title: 'hklm\Software\foo\bar'
      },
    ].each do |testcase|
      context testcase[:context] do
        let(:instance) { described_class.new(title: testcase[:reg_value_title], catalog:) }

        it 'does not autorequire ancestor keys if none exist' do
          expect(instance.autorequire).to eq([])
        end

        it 'onlies autorequire the nearest ancestor registry_key resource' do
          catalog.add_resource(Puppet::Type.type(:registry_key).new(path: 'hklm\Software', catalog:))
          catalog.add_resource(Puppet::Type.type(:registry_key).new(path: 'hklm\Software\foo', catalog:))
          catalog.add_resource(Puppet::Type.type(:registry_key).new(path: 'hklm\Software\foo\bar', catalog:))

          autorequire_array = instance.autorequire
          expect(autorequire_array.count).to eq(1)
          expect(autorequire_array[0].to_s).to eq("Registry_key[#{testcase[:expected_reg_key_title]}] => Registry_value[#{testcase[:reg_value_title]}]")
        end
      end
    end
  end

  describe 'type property' do
    let(:value) { described_class.new(path: 'hklm\software\foo', catalog:) }

    [:string, :array, :dword, :qword, :binary, :expand].each do |type|
      it "supports a #{type} type" do
        value[:type] = type
        expect(value[:type].should == type)
      end
    end

    it 'rejects other types' do
      expect { value[:type] = 'REG_SZ' }.to raise_error(Puppet::Error)
    end
  end

  describe 'data property' do
    let(:value) { described_class.new(path: 'hklm\software\foo', catalog:) }

    context 'with string data' do
      ['', 'foobar'].each do |data|
        it "accepts '#{data}'" do
          value[:type] = :string
          expect(value[:data] = data)
        end
      end
    end

    context 'with integer data' do
      [:dword, :qword].each do |type|
        context "when #{type}" do
          arr1 = [0, 0xFFFFFFFF, -1, 42]
          arr1.each do |data|
            it "accepts #{data}" do
              value[:type] = type
              expect(value[:data] = data)
            end
          end
          arr2 = ['foobar', ':true']
          arr2.each do |data|
            it "rejects #{data}" do
              value[:type] = type
              expect { value[:data] = data }.to raise_error(Puppet::Error)
            end
          end
        end
      end

      context 'when 64-bit integers' do
        let(:data) { 0xFFFFFFFFFFFFFFFF }

        it 'accepts qwords' do
          value[:type] = :qword
          expect(value[:data] = data)
        end

        it 'rejects dwords' do
          value[:type] = :dword
          expect { value[:data] = data }.to raise_error(Puppet::Error)
        end
      end
    end

    context 'when binary data' do
      # rubocop:disable RSpec/RepeatedExample
      ['', 'CA FE BE EF', 'DEADBEEF'].each do |data|
        it "accepts '#{data}'" do
          value[:type] = :binary
          expect(value[:data] = data)
        end
      end
      [9, '1', 'A'].each do |data|
        it "accepts '#{data}' and have a leading zero" do
          value[:type] = :binary
          expect(value[:data] = data)
        end
      end
      # rubocop:enable RSpec/RepeatedExample

      ["\040\040", 'foobar', true].each do |data|
        it "rejects '#{data}'" do
          value[:type] = :binary
          expect { value[:data] = data }.to raise_error(Puppet::Error)
        end
      end
    end

    context 'when array data' do
      it 'supports array data' do
        value[:type] = :array
        expect(value[:data] = ['foo', 'bar', 'baz'])
      end

      it 'supports an empty array' do
        value[:type] = :array
        expect(value[:data] = [])
      end

      [[''], nil, ['', 'foo', 'bar'], ['foo', '', 'bar'], ['foo', 'bar', '']].each do |data|
        it "rejects '#{data}'" do
          value[:type] = :array
          expect { value[:data] = data }.to raise_error(Puppet::Error)
        end
      end
    end

    context 'when sensitive data' do
      it 'supports Sensitive[String] for string type' do
        value[:type] = :string
        sensitive_data = Puppet::Pops::Types::PSensitiveType::Sensitive.new('secret_password')
        expect(value[:data] = sensitive_data)
      end

      it 'supports Sensitive[String] for expand type' do
        value[:type] = :expand
        sensitive_data = Puppet::Pops::Types::PSensitiveType::Sensitive.new('secret_path')
        expect(value[:data] = sensitive_data)
      end

      it 'supports Sensitive[String] in array type' do
        value[:type] = :array
        sensitive_data = ['public_value', Puppet::Pops::Types::PSensitiveType::Sensitive.new('secret_value'), 'another_public']
        expect(value[:data] = sensitive_data)
      end

      it 'supports Sensitive[String] for binary type' do
        value[:type] = :binary
        sensitive_data = Puppet::Pops::Types::PSensitiveType::Sensitive.new('CAFEBEEF')
        expect(value[:data] = sensitive_data)
      end
    end
  end
end
