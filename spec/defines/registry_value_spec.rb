require 'spec_helper'

describe 'registry::value' do

  %w(redhat ubuntu debian).each do |os|
    describe "Attempt using with #{os}" do
      let(:params){{:key =>'HKLM\Software\Vendor\PuppetLabs',:value => 'Awesome'}}
      let(:title){'test'}
      let(:facts){{:operatingsystem => os}}
      it{
          expect{
            should contain_registry_value('test')
          }.to raise_error(Puppet::Error, /Unsupported OS #{os}/i)
      }
    end
  end
end