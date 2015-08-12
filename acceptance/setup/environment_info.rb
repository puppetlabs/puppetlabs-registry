test_name "Expose Environment Information" do
  hosts.each do |host|
    if host['platform'] =~ /windows/
      on host, shell('cmd /c SET', { :accept_all_exit_codes => true })
      on host, shell('cmd /c puppet -V', { :accept_all_exit_codes => true })
      on host, shell('cmd /c facter -v', { :accept_all_exit_codes => true })
      on host, shell('cmd /c facter', { :accept_all_exit_codes => true })
    end
  end
end
