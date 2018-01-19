#!/usr/bin/env ruby -S rspec
require 'spec_helper'
require 'puppet/type/registry_value'

describe Puppet::Type.type(:registry_value) do
  let (:catalog) do Puppet::Resource::Catalog.new end

  [:ensure, :type, :data].each do |property|
    it "should have a #{property} property" do
      described_class.attrclass(property).ancestors.should be_include(Puppet::Property)
    end

    it "should have documentation for its #{property} property" do
      described_class.attrclass(property).doc.should be_instance_of(String)
    end
  end

  describe "path parameter" do
    it "should have a path parameter" do
      Puppet::Type.type(:registry_value).attrtype(:path).should == :param
    end

    %w[hklm\propname hklm\software\propname].each do |path|
      it "should accept #{path}" do
        described_class.new(:path => path, :catalog => catalog)
      end
    end

    %w[hklm\\ hklm\software\\ hklm\software\vendor\\].each do |path|
      it "should accept the unnamed (default) value: #{path}" do
        described_class.new(:path => path, :catalog => catalog)
      end
    end

    it "should strip trailling slashes from unnamed values" do
      value = described_class.new(:path => 'hklm\\software\\\\', :catalog => catalog)

      expect(value[:path]).to eq('hklm\\software\\')
    end

    %w[HKEY_DYN_DATA\\ HKEY_PERFORMANCE_DATA\name].each do |path|
      it "should reject #{path} as unsupported" do
        expect { described_class.new(:path => path, :catalog => catalog) }.to raise_error(Puppet::Error, /Unsupported/)
      end
    end

    %w[hklm hkcr unknown\\name unknown\\subkey\\name].each do |path|
      it "should reject #{path} as invalid" do
        expect { described_class.new(:path => path, :catalog => catalog) }.to raise_error(Puppet::Error, /Invalid registry key/)
      end
    end

    %w[HKLM\\name HKEY_LOCAL_MACHINE\\name hklm\\name].each do |root|
      it "should canonicalize root key #{root}" do
        value = described_class.new(:path => root, :catalog => catalog)
        value[:path].should == 'hklm\name'
      end
    end

    %w[HKLM\Software\\\\nam\\e HKEY_LOCAL_MACHINE\Software\\\\nam\\e hklm\Software\\\\nam\\e].each do |root|
      it "should use a double backslash when canonicalizing value names with a backslash #{root}" do
        value = described_class.new(:path => root, :catalog => catalog)
        value[:path].should == 'hklm\Software\\\\nam\e'
      end
    end

    {
      'HKLM\\Software\\\\Middle\\\\Slashes'  => 'hklm\\Software\\\\Middle\\\\Slashes',
      'HKLM\\Software\\\\\\\\LeadingSlashes' => 'hklm\\Software\\\\\\\\LeadingSlashes',
      'HKLM\\Software\\\\TrailingSlashes\\'  => 'hklm\\Software\\\\TrailingSlashes\\',
      'HKLM\\Software\\\\\\'                 => 'hklm\\Software\\\\\\', # A value name of backslash
    }.each do |testcase, expected_value|
      it "should use a double backslash as a delimeter between path and value for title #{testcase}" do
        value = described_class.new(:path => testcase, :catalog => catalog)
        value[:path].should == expected_value
      end
    end

    it 'should validate the length of the value name'
    it 'should validate the length of the value data'
    it 'should be case-preserving'
    it 'should be case-insensitive'
    it 'should support 32-bit values' do
      value = described_class.new(:path => '32:hklm\software\foo', :catalog => catalog)
    end
  end

  describe '#autorequire' do
    let(:subject) { described_class.new(:title => subject_title, :catalog => catalog) }
    [
      {
        :context                => 'with a non-default value_name',
        :reg_value_title        => 'hklm\software\foo\bar',
        :expected_reg_key_title => 'hklm\Software\foo',
      },
      {
        :context                => 'with a mixed case path and value_name',
        :reg_value_title        => 'hkLm\soFtwarE\fOo\Bar',
        :expected_reg_key_title => 'hklm\Software\foo',
      },
      {
        :context                => 'with a default value_name',
        :reg_value_title        => 'hklm\software\foo\bar\\',
        :expected_reg_key_title => 'hklm\Software\foo\bar',
      },
      {
        :context                => 'with a value whose parent key is not managed but does have an ancestor key in the catalog',
        :reg_value_title        => 'hklm\software\foo\bar\baz\alice',
        :expected_reg_key_title => 'hklm\Software\foo\bar',
      }
    ].each do |testcase|
      context testcase[:context] do
        let(:subject) { described_class.new(:title => testcase[:reg_value_title], :catalog => catalog) }

        it 'should not autorequire ancestor keys if none exist' do
          expect(subject.autorequire).to eq([])
        end

        it 'should only autorequire the nearest ancestor registry_key resource' do
          catalog.add_resource(Puppet::Type.type(:registry_key).new(:path => 'hklm\Software', :catalog => catalog))
          catalog.add_resource(Puppet::Type.type(:registry_key).new(:path => 'hklm\Software\foo', :catalog => catalog))
          catalog.add_resource(Puppet::Type.type(:registry_key).new(:path => 'hklm\Software\foo\bar', :catalog => catalog))

          autorequire_array = subject.autorequire
          expect(autorequire_array.count).to eq(1)
          expect(autorequire_array[0].to_s).to eq("Registry_key[#{testcase[:expected_reg_key_title]}] => Registry_value[#{testcase[:reg_value_title]}]")
        end
      end
    end
  end

  describe "type property" do
    let (:value) { described_class.new(:path => 'hklm\software\foo', :catalog => catalog) }

    [:string, :array, :dword, :qword, :binary, :expand].each do |type|
      it "should support a #{type.to_s} type" do
        value[:type] = type
        value[:type].should == type
      end
    end

    it "should reject other types" do
      expect { value[:type] = 'REG_SZ' }.to raise_error(Puppet::Error)
    end
  end

  describe "data property" do
    let (:value) { described_class.new(:path => 'hklm\software\foo', :catalog => catalog) }

    context "string data" do
      ['', 'foobar'].each do |data|
        it "should accept '#{data}'" do
          value[:type] = :string
          value[:data] = data
        end
      end

      pending "it should accept nil"
    end

    context "integer data" do
      [:dword, :qword].each do |type|
        context "for #{type}" do
          [0, 0xFFFFFFFF, -1, 42].each do |data|
            it "should accept #{data}" do
              value[:type] = type
              value[:data] = data
            end
          end

          %w['foobar' :true].each do |data|
            it "should reject #{data}" do
              value[:type] = type
              expect { value[:data] = data }.to raise_error(Puppet::Error)
            end
          end
        end
      end

      context "for 64-bit integers" do
        let :data do 0xFFFFFFFFFFFFFFFF end

        it "should accept qwords" do
          value[:type] = :qword
          value[:data] = data
        end

        it "should reject dwords" do
          value[:type] = :dword
          expect { value[:data] = data }.to raise_error(Puppet::Error)
        end
      end
    end

    context "binary data" do
      ['', 'CA FE BE EF', 'DEADBEEF'].each do |data|
        it "should accept '#{data}'" do
          value[:type] = :binary
          value[:data] = data
        end
      end
      [9,'1','A'].each do |data|
        it "should accept '#{data}' and have a leading zero" do
          value[:type] = :binary
          value[:data] = data
        end
      end

      ["\040\040", 'foobar', :true].each do |data|
        it "should reject '#{data}'" do
          value[:type] = :binary
          expect { value[:data] = data }.to raise_error(Puppet::Error)
        end
      end
    end

    context "array data" do
      it "should support array data" do
        value[:type] = :array
        value[:data] = ['foo', 'bar', 'baz']
      end
    end
  end
end
