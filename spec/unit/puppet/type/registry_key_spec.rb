#!/usr/bin/env rspec
require 'spec_helper'
require 'puppet/modules/registry/registry_base'

describe Puppet::Type.type(:registry_key) do
  let (:key) { Puppet::Type.type(:registry_key).new(:path => 'HKLM\Software') }

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

    %w[hklm hklm\software hklm\software\vendor].each do |path|
      it "should accept #{path}" do
        key[:path] = path
      end
    end

    %w[HKEY_DYN_DATA HKEY_PERFORMANCE_DATA].each do |path|
      it "should reject #{path} as unsupported case insensitively" do
        expect { key[:path] = path }.should raise_error(Puppet::Error, /Unsupported/)
      end
    end

    %[hklm\\ hklm\foo\\ unknown unknown\subkey].each do |path|
      it "should reject #{path} as invalid" do
        path = "hklm\\" + 'a' * 256
        expect { key[:path] = path }.should raise_error(Puppet::Error, /Invalid registry key/)
      end
    end

    %w[HKLM HKEY_LOCAL_MACHINE hklm].each do |root|
      it "should canonicalize the root key #{root}" do
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
