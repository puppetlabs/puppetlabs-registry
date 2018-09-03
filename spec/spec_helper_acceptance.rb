require 'beaker-pe'
require 'beaker-puppet'
require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'
require 'beaker/testmode_switcher'
require 'beaker/testmode_switcher/dsl'

run_puppet_install_helper
configure_type_defaults_on(hosts)

install_module_dependencies_on(hosts)

proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
staging = { module_name: 'puppetlabs-registry' }
local = { module_name: 'registry', source: proj_root }

hosts.each do |host|
  # Install Registry Module
  # in CI allow install from staging forge, otherwise from local
  install_dev_puppet_module_on(host, options[:forge_host] ? staging : local)
end

def is_x64(agent)
  on(agent, facter('architecture')).stdout.chomp == 'x64'
end

def windows_agents
  agents.select { |agent| agent['platform'].include?('windows') }
end

def random_string(length)
  chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
  str = ''
  1.upto(length) { |i| str << chars[rand(chars.size-1)] }
  return str
end

def get_apply_opts(environment_hash = nil)
  opts = {
      :catch_failures => true,
      :acceptable_exit_codes => [0, 2],
  }
  opts.merge!(:environment => environment_hash) if environment_hash
  opts
end

def native_sysdir(agent)
  if is_x64(agent)
    if on(agent, 'ls /cygdrive/c/windows/sysnative', :acceptable_exit_codes => (0..255)).exit_code == 0
      '`cygpath -W`/sysnative'
    else
      nil
    end
  else
    '`cygpath -S`'
  end
end
