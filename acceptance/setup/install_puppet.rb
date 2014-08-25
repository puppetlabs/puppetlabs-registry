test_name "Installing Puppet" do
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '../..'))
  version = ENV['PUPPET_VERSION'] || '3.6.2-1066-g5010aba-x64'
  download_url = ENV['WIN_DOWNLOAD_URL'] || 'http://builds.puppetlabs.lan/puppet/5010aba1b89f04788736dd49227c46617516bb92/artifacts/windows/'
  hosts.each do |host|
    if host['platform'] =~ /windows/
      install_puppet_from_msi(host,
                              {
                                  :win_download_url => download_url,
                                  :version => version
                              })
      step "Install Registry to host"
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
