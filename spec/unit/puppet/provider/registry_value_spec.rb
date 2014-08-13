#! /usr/bin/env ruby

require 'spec_helper'
require 'puppet/type/registry_value'

describe Puppet::Type.type(:registry_value).provider(:registry), :if => Puppet.features.microsoft_windows? do
  let (:catalog) do Puppet::Resource::Catalog.new end
  let (:type) { Puppet::Type.type(:registry_value) }

  describe "#exists?" do
    it "should return true for a well known hive" do
      reg_value = type.new(:path => 'hklm\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareType', :provider => described_class.name)
      reg_value.provider.exists?.should be_true
    end

    it "should return false for a bogus hive/path" do
      reg_value = type.new(:path => 'hklm\foobar5000', :catalog => catalog, :provider => described_class.name)
      reg_value.provider.exists?.should be_false
    end
  end

  describe "#regvalue" do
    it "should return a valid string for a well known key" do
      reg_value = type.new(:path => 'hklm\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareType', :provider => described_class.name)
      reg_value.provider.data.should eq ['System']
      reg_value.provider.type.should eq :string
    end
  end
end
