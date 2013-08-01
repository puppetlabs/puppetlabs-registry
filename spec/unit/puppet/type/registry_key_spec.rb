#!/usr/bin/env ruby -S rspec
require 'spec_helper'
require 'puppet/resource'
require 'puppet/resource/catalog'
require 'puppet/type/registry_key'

describe Puppet::Type.type(:registry_key) do
  let (:catalog) do Puppet::Resource::Catalog.new end

  # This is overridden here so we get a consistent association with the key
  # and a catalog using memoized let methods.
  let (:subject) do
    described_class.new(:name => 'HKLM\Software', :catalog => catalog)
  end

  [:ensure].each do |property|
    it "should have a #{property} property" do
      described_class.attrclass(property).ancestors.should be_include(Puppet::Property)
    end

    it "should have documentation for its #{property} property" do
      described_class.attrclass(property).doc.should be_instance_of(String)
    end
  end

  describe "path parameter" do
    it "has a path parameter" do
      expect(described_class.attrtype(:path)).to eq(:param)
    end

    %w[hklm hklm\software hklm\software\vendor].each do |path|
      it "should accept #{path}" do
        subject[:path] = path
      end
    end

    %w[HKEY_DYN_DATA HKEY_PERFORMANCE_DATA].each do |path|
      it "should reject #{path} as unsupported case insensitively" do
        expect { subject[:path] = path }.should raise_error(Puppet::Error, /Unsupported/)
      end
    end

    %w[hklm\\ hklm\foo\\ unknown unknown\subkey \:hkey].each do |path|
      it "should reject #{path} as invalid" do
        path = "hklm\\" + 'a' * 256
        expect { subject[:path] = path }.should raise_error(Puppet::Error, /Invalid registry key/)
      end
    end

    %w[HKLM HKEY_LOCAL_MACHINE hklm].each do |root|
      it "should canonicalize the root key #{root}" do
        subject[:path] = root
        subject[:path].should == 'hklm'
      end
    end

    it 'should be case-preserving'
    it 'should be case-insensitive'
    it 'should autorequire ancestor keys'
    it 'should support 32-bit keys' do
      subject[:path] = '32:hklm\software'
    end
  end

  describe "#eval_generate" do
    context "not purging" do
      it "should return an empty array" do
        subject.eval_generate.should be_empty
      end
    end

    context "purging" do
      let (:catalog) do Puppet::Resource::Catalog.new end

      # This is overridden here so we get a consistent association with the key
      # and a catalog using memoized let methods.
      let (:subject) do
        Puppet::Type.type(:registry_key).new(:name => 'HKLM\Software', :catalog => catalog)
      end

      before :each do
        subject[:purge_values] = true
        catalog.add_resource(subject)
        catalog.add_resource(Puppet::Type.type(:registry_value).new(:path => "#{subject[:path]}\\val1", :catalog => catalog))
        catalog.add_resource(Puppet::Type.type(:registry_value).new(:path => "#{subject[:path]}\\val2", :catalog => catalog))
      end

      it "should return an empty array if the key doesn't have any values" do
        expect(subject.provider).to receive(:values).and_return([])
        subject.eval_generate.should be_empty
      end

      it "should purge existing values that are not being managed" do
        expect(subject.provider).to receive(:values).and_return(['val1', 'val3'])
        res = subject.eval_generate.first

        res[:ensure].should == :absent
        res[:path].should == "#{subject[:path]}\\val3"
      end

      it "should return an empty array if all existing values are being managed" do
        expect(subject.provider).to receive(:values).and_return(['val1', 'val2'])
        subject.eval_generate.should be_empty
      end
    end
  end

  describe "#autorequire" do
    let :the_catalog do
      Puppet::Resource::Catalog.new
    end

    let(:the_resource_name) { 'HKLM\Software\Vendor\PuppetLabs' }

    let :the_resource do
      # JJM Holy cow this is an intertangled mess.  ;)
      resource = described_class.new(:name => the_resource_name, :catalog => the_catalog)
      the_catalog.add_resource resource
      resource
    end

    it 'Should initialize the catalog instance variable' do
      expect(the_resource.catalog).to be the_catalog
    end

    it 'Should allow case insensitive lookup using the downcase path' do
      expect(the_resource).to be the_catalog.resource(:registry_key, the_resource_name.downcase)
    end

    it 'Should preserve the case of the user specified path' do
      expect(the_resource).to be the_catalog.resource(:registry_key, the_resource_name)
    end

    it 'Should return the same resource regardless of the alias used' do
      expect(the_resource).to be the_catalog.resource(:registry_key, the_resource_name)
      expect(the_resource).to be the_catalog.resource(:registry_key, the_resource_name.downcase)
    end
  end
end
