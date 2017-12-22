#!/usr/bin/env ruby -S rspec
require 'spec_helper'
require 'puppet/type/registry_value'

# Helper method used when display describe text blocks to distinguish
# between empty strings and nils
def display_nil_string(value)
  value.nil? ? '(nil)' : value
end

describe Puppet::Type.type(:registry_value) do
  let (:title) { 'TestRegistryValue' }
  let (:catalog) do Puppet::Resource::Catalog.new end

  [:ensure, :type, :data].each do |property|
    it "should have a #{property} property" do
      described_class.attrclass(property).ancestors.should be_include(Puppet::Property)
    end

    it "should have documentation for its #{property} property" do
      described_class.attrclass(property).doc.should be_instance_of(String)
    end
  end

  describe "value_name parameter" do
    it "should have a value_name parameter" do
      Puppet::Type.type(:registry_value).attrtype(:value_name).should == :param
    end
  end

  describe "path parameter" do
    it "should have a path parameter" do
      Puppet::Type.type(:registry_value).attrtype(:path).should == :param
    end

    %w[hklm hklm\ hklm\propname hklm\software\propname].each do |path|
      it "should accept #{path}" do
        described_class.new(:title => title, :path => path, :catalog => catalog)
      end
    end

    it "should strip trailling slashes from paths" do
      value = described_class.new(:title => title, :path => 'hklm\\software\\\\', :catalog => catalog)

      expect(value[:path]).to eq('hklm\\software')
    end

    %w[HKEY_DYN_DATA\\ HKEY_PERFORMANCE_DATA\name].each do |path|
      it "should reject #{path} as unsupported" do
        expect { described_class.new(:title => title, :path => path, :catalog => catalog) }.to raise_error(Puppet::Error, /Unsupported/)
      end
    end

    %w[unknown\\name unknown\\subkey\\name].each do |path|
      it "should reject #{path} as invalid" do
        expect { described_class.new(:title => title, :path => path, :catalog => catalog) }.to raise_error(Puppet::Error, /Invalid registry key/)
      end
    end

    %w[HKLM\\name HKEY_LOCAL_MACHINE\\name hklm\\name].each do |root|
      it "should canonicalize root key #{root}" do
        value = described_class.new(:title => title, :path => root, :catalog => catalog)
        value[:path].should == 'hklm\name'
      end
    end

    it 'should accept 32-bit values' do
      described_class.new(:title => title, :path => '32:hklm\software\foo', :catalog => catalog)
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
    let (:value) { described_class.new(:title => title, :path => 'hklm\software\foo', :catalog => catalog) }

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

  describe "title property" do
    [ { :title => 'hklm\software\foo',
        :expected_path       => 'hklm\software',
        :expected_value_name => 'foo',
      },
      # Default values are specified with a trailing slash
      { :title => 'hklm\software\foo\\',
        :expected_path       => 'hklm\software\foo',
        :expected_value_name => '',
      },
      # Default values are specified with an empty value_name
      { :title => 'hklm\software\foo',
        :value_name          => '',
        :expected_path       => 'hklm\software',
        :expected_value_name => '',
      },
      # Explicit paths should overried title
      { :title => 'hklm\software\foo',
        :path                => 'hklm\different\path',
        :value_name          => 'value1',
        :expected_path       => 'hklm\different\path',
        :expected_value_name => 'value1',
      },
      # Explicit value names should overried title
      { :title => 'hklm\software\foo',
        :value_name          => 'value1',
        :expected_path       => 'hklm\software\foo',
        :expected_value_name => 'value1',
      },
      { :title => 'hklm\software\foo',
        :value_name          => 'value\1',
        :expected_path       => 'hklm\software\foo',
        :expected_value_name => 'value\1',
      },
      { :title => 'hklm\software\foo',
        :value_name          => 'value1\\',
        :expected_path       => 'hklm\software\foo',
        :expected_value_name => 'value1\\',
      }].each do |testcase|

      context "given a title of '#{testcase[:title]}', path of '#{display_nil_string(testcase[:path])}', and value_name of '#{display_nil_string(testcase[:value_name])}'" do
        let (:value) {
          params = {
            :title => testcase[:title],
            :catalog => catalog
          }
          params[:value_name] = testcase[:value_name] unless testcase[:value_name].nil?
          params[:path] = testcase[:path] unless testcase[:path].nil?

          described_class.new(params)
        }

        it "should use registry value name of '#{testcase[:expected_value_name]}'" do
          expect(value[:value_name]).to eq(testcase[:expected_value_name])
        end
        it "should use registry path of '#{testcase[:expected_path]}'" do
          expect(value[:path]).to eq(testcase[:expected_path])
        end
      end
    end
  end

  describe "data property" do
    let (:value) { described_class.new(:title => title, :path => 'hklm\software\foo', :catalog => catalog) }

    context "string data" do
      ['', 'foobar'].each do |data|
        it "should accept '#{data}'" do
          value[:type] = :string
          value[:data] = data
        end
      end
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
