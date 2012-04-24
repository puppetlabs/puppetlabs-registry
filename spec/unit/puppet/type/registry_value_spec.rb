#!/usr/bin/env rspec
require 'spec_helper'
require 'puppet/modules/registry/registry_base'

describe Puppet::Type.type(:registry_value) do
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
      Puppet::Type.type(:registry_key).attrtype(:path).should == :param
    end

    %w[hklm\propname hklm\software\propname].each do |path|
      it "should accept #{path}" do
        described_class.new(:path => path)
      end
    end

    %w[hklm\\ hklm\software\\ hklm\software\vendor\\].each do |path|
      it "should accept the unnamed (default) value: #{path}" do
        described_class.new(:path => path)
      end
    end

    it "should strip trailling slashes from unnamed values" do
      described_class.new(:path => 'hklm\\software\\\\')
    end

    %w[HKEY_DYN_DATA\\ HKEY_PERFORMANCE_DATA\name].each do |path|
      it "should reject #{path} as unsupported" do
        expect { described_class.new(:path => path) }.to raise_error(Puppet::Error, /Unsupported/)
      end
    end

    %[hklm hkcr unknown\\name unknown\\subkey\\name].each do |path|
      it "should reject #{path} as invalid" do
        pending 'wrong message'
        expect { described_class.new(:path => path) }.should raise_error(Puppet::Error, /Invalid registry key/)
      end
    end

    %w[HKLM\\name HKEY_LOCAL_MACHINE\\name hklm\\name].each do |root|
      it "should canonicalize root key #{root}" do
        value = described_class.new(:path => root)
        value[:path].should == 'hklm\name'
      end
    end

    it 'should validate the length of the value name'
    it 'should validate the length of the value data'
    it 'should be case-preserving'
    it 'should be case-insensitive'
    it 'should autorequire ancestor keys'

    it 'should support 32-bit values' do
      value = described_class.new(:path => '32:hklm\software\foo')
      value.parameter(:path).access.should == 0x200
    end
  end

  describe "type property" do
    let (:value) { described_class.new(:path => 'hklm\software\foo') }

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
    let (:value) { described_class.new(:path => 'hklm\software\foo') }

    it "should support string data" do
      value[:type] = :string
      value[:data] = 'foobar'
    end

    it "should support dword data" do
      value[:type] = :dword
      value[:data] = 0
    end

    it "should support qword data" do
      value[:type] = :qword
      value[:data] = 0xFFFF
    end

    it "should support binary data" do
      value[:type] = :binary
      value[:data] = "CA FE BE EF"
    end

    it "should support array data" do
      value[:type] = :array
      value[:data] = ['foo', 'bar', 'baz']
    end
  end
end
