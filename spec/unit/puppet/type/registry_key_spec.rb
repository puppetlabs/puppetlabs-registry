#!/usr/bin/env rspec
require 'spec_helper'
require 'puppet/util/registry_base'

describe Puppet::Type.type(:registry_key) do
  let (:path) { 'HKLM\Software\PuppetSpecTest' }
  let (:key) { Puppet::Type.type(:registry_key).new(:path => path) }

  [:ensure].each do |property|
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
      key[:path].should == path
    end

    Puppet::Util::RegistryBase::HKEYS.each do |hkey|
      it "should accept #{hkey}\\Subkey" do
        described_class.new(:path => "#{hkey}\\Subkey")
      end
    end

    it 'should reject unknown keys' do
      expect { key[:path] = 'UNKNOWN\Subkey' }.should raise_error(Puppet::Error)
    end

    it 'should accept a valid root key' do
      key[:path] = 'HKLM'
    end

    it 'should reject an unknown root key' do
      expect { key[:path] = 'UNKNOWN' }.should raise_error(Puppet::Error)
    end

    %w[HKLM HKEY_LOCAL_MACHINE hklm].each do |root|
      it "should canonicalize the root key #{root}" do
        pending("Not implemented")
        key[:path] = root
        key[:path].should == 'hklm'
      end
    end

    it 'should be case-preserving'
    it 'should be case-insensitive'
    it 'should autorequire ancestor keys'
  end

  describe "redirect parameter" do
    it 'should not redirect by default' do
      key[:redirect].should == :false
    end

    it 'should allow redirection' do
      key[:redirect] = true
      key[:redirect].should be_true
    end
  end
end
