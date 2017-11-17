require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'

run_puppet_install_helper

install_module_dependencies_on(hosts)

test_name "Installing Puppet Modules" do
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  hosts.each do |host|
    if host['platform'] =~ /windows/
      on host, "mkdir -p #{host['distmoduledir']}/registry"
      target = (on host, "echo #{host['distmoduledir']}/registry").raw_output.chomp

      %w(lib manifests metadata.json).each do |file|
        scp_to host, "#{proj_root}/#{file}", target
      end
    end
  end
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
