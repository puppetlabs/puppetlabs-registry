test_name "Installing Puppet Agent" do
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '../..'))
  version = ENV['PUPPET_AGENT_VERSION'] || '0.9.1'
  download_url = ENV['WIN_DOWNLOAD_URL'] || 'http://builds.puppetlabs.lan/'
  hosts.each do |host|
    if host['platform'] =~ /windows/
      install_puppetagent_dev_repo(host,
                              {
                                  :dev_builds_url => download_url,
                                  :version => version
                              })
      step "Install Registry to host"
      on host, "mkdir -p #{host['distmoduledir']}/registry"
      result = on host, "echo #{host['distmoduledir']}/registry"
      target = result.raw_output.chomp

      %w(lib manifests metadata.json).each do |file|
        scp_to host, "#{proj_root}/#{file}", target
      end
      on host, shell('curl -k -o c:/puppetlabs-stdlib-4.5.1.tar.gz https://forgeapi.puppetlabs.com/v3/files/puppetlabs-stdlib-4.5.1.tar.gz')
      on host, puppet('module install c:/puppetlabs-stdlib-4.5.1.tar.gz --force --ignore-dependencies'), {:acceptable_exit_codes => [0, 1]}
    end
  end
end
