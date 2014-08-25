test_name "Installing Puppet Enterprise" do
  install_pe

  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '../..'))
  agents.each do |host|
    if host['platform'] =~ /windows/i
      on host, "mkdir -p #{host['distmoduledir']}/registry"
      result = on host, "echo #{host['distmoduledir']}/registry"
      target = result.raw_output.chomp

      %w(lib manifests metadata.json).each do |file|
        scp_to host, "#{proj_root}/#{file}", target
      end
      on host, "cd #{host['distmoduledir']} && git clone --branch 4.3.2 --depth 1 http://github.com/puppetlabs/puppetlabs-stdlib stdlib"
    end
  end
end
