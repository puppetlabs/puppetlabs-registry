#! /usr/bin/env ruby

require 'spec_helper'
require 'puppet/type/registry_key'

describe Puppet::Type.type(:registry_key).provider(:registry), :if => Puppet.features.microsoft_windows? do
  let (:catalog) do Puppet::Resource::Catalog.new end
  let (:type) { Puppet::Type.type(:registry_key) }

  describe "#destroy" do
    it "can destroy a randomly created key" do

      guid = SecureRandom.uuid
      reg_key = type.new(:path => "hklm\\SOFTWARE\\Puppet Labs\\PuppetRegProviderTest\\#{guid}", :provider => described_class.name)
      already_exists = reg_key.provider.exists?
      already_exists.should be_false

      # something has gone terribly wrong here, pull the ripcord
      break if already_exists

      reg_key.provider.create
      reg_key.provider.exists?.should be_true

      # test FFI code
      reg_key.provider.destroy
      reg_key.provider.exists?.should be_false
    end
  end
end
