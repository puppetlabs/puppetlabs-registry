#!/usr/bin/env rspec
require 'spec_helper'
require 'puppet/util/registry_base'

describe Puppet::Type.type(:registry_value) do
  let (:path) { 'HKLM\Software\PuppetSpecTest\ValueName' }
  let (:value) { Puppet::Type.type(:registry_value).new(:path => path) }

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

    it 'should accept a fully qualified path' do
      value[:path].should == path
    end

    Puppet::Util::RegistryBase::HKEYS.each do |hkey|
      it "should accept #{hkey}\Subkey\value" do
        Puppet::Type.type(:registry_key).new(:path => "#{hkey}\\Subkey\\value")
      end
    end

    it 'should reject a root key' do
      pending("Should it allow default value of root key")
      expect { value[:path] = 'HKLM' }.should raise_error(Puppet::Error)
    end

    it 'should reject unknown root keys' do
      pending("This is not working")
      expect { value[:path] = 'UNKNOWN\Bar\Baz' }.should raise_error(Puppet::Error)
    end

    it 'should canonicalize the root key'
    it 'should be case-preserving'
    it 'should be case-insensitive'
    it 'should autorequire ancestor keys'
  end

  describe "redirect parameter" do
    it 'should not redirect by default' do
      value[:redirect].should == :false
    end

    it 'should allow redirection' do
      value[:redirect] = true
      value[:redirect].should be_true
    end
  end

  describe "default parameter" do
    it 'should not refer to the "default" value by default' do
      value[:default].should == :false
    end

    it 'should allow default' do
      value[:default] = true
      value[:default].should be_true
    end
  end

  describe "type property" do
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
    it "should support string data" do
      value[:type] = :string
      value[:data] = 'foobar'
    end

    it "should support integer data" do
      value[:type] = :dword
      value[:data] = 0
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
