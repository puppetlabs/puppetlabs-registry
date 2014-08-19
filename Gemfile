source ENV['GEM_SOURCE'] || 'https://rubygems.org'

def location_for(place, fake_version = nil)
  if place =~ /^(git[:@][^#]*)#(.*)/
    [fake_version, { :git => $1, :branch => $2, :require => false }].compact
  elsif place =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place, { :require => false }]
  end
end

group :development, :test do
  gem 'rake',                    :require => false
  gem 'mocha', '~>0.10.5',       :require => false
  gem 'puppetlabs_spec_helper',  :require => false
  gem 'serverspec',              :require => false
  gem 'puppet-lint',             :require => false
  gem 'pry',                     :require => false
  gem 'simplecov',               :require => false
  gem 'rspec', '~>2.14.0',       :require => false
  gem 'beaker',                  :require => false, :platforms => :ruby
end

is_x64 = Gem::Platform.local.cpu == 'x64'
if is_x64
  platform(:x64_mingw) do
    gem "win32-dir", "~> 0.4.9", :require => false
    gem "win32-process", "~> 0.7.4", :require => false
    gem "win32-service", "~> 0.8.4", :require => false
    gem "minitar", "~> 0.5.4", :require => false
  end
else
  platform(:mingw) do
    gem "win32-process", "~> 0.6.5", :require => false
    gem "win32-service", "~> 0.7.2", :require => false
    gem "minitar", "~> 0.5.4", :require => false
    gem "win32console", :require => false
  end
end

ENV['GEM_PUPPET_VERSION'] ||= ENV['PUPPET_GEM_VERSION']
puppetversion = ENV['GEM_PUPPET_VERSION']
if puppetversion
  gem 'puppet', *location_for(puppetversion)
else
  gem 'puppet', :require => false
end

# vim:ft=ruby
