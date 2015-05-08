require 'facter'

## Define our Facts as nil first
username = nil
name = nil
domain = nil
sid = nil

## Fact for full username of the currently/recently logged in user... usually helpful for Endpoints
Facter.add("windows_currentuser_username") do
  confine :kernel => 'windows'
  setcode do
    require 'win32ole'
    wmi = WIN32OLE.connect('winmgmts://./root/CIMV2')
    ## First find out
    query1 = "select Username from win32_computersystem"
    wmi.ExecQuery(query1).each do |data|
      if data.Username.nil?
        username = nil
      else
        domain, name = data.Username.split("\\")
        username = data.Username
      end

    end
    if username.nil?
      sid = nil
    else
      query2 = "select sid from win32_useraccount where name='"+ name +"' and domain='"+ domain +"'"
      wmi.ExecQuery(query2).each do |data|
        sid = data.SID
      end
    end
    username
  end
end

## Fact for sid of current user....
Facter.add("windows_currentuser_sid") do
  confine :kernel => 'windows'
  setcode do
    sid
  end
end

## Fact for just name of current user
Facter.add("windows_currentuser_name") do
  confine :kernel => 'windows'
  setcode do
    name
  end
end

## Fact for just domain of current user
Facter.add("windows_currentuser_domain") do
  confine :kernel => 'windows'
  setcode do
    domain
  end
end