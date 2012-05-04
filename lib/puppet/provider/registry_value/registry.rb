require 'puppet/type'
Puppet::Type.type(:registry_value).provide(:registry) do
  require 'pathname' # JJM WORK_AROUND #14073
  require Pathname.new(__FILE__).dirname.dirname.dirname.expand_path + 'modules/registry/registry_base'
  include Puppet::Modules::Registry::RegistryBase

  defaultfor :operatingsystem => :windows
  confine    :operatingsystem => :windows

  def self.instances
    []
  end

  def create
    Puppet.debug("Creating registry value: #{self}")
    valuepath.hkey.open(valuepath.subkey, Win32::Registry::KEY_ALL_ACCESS | valuepath.access) do |reg|
      ary = to_native(resource[:type], resource[:data])
      reg.write(valuepath.valuename, ary[0], ary[1])
    end
  end

  def exists?
    Puppet.debug("Checking the existence of registry value: #{self}")
    found = false
    valuepath.hkey.open(valuepath.subkey, Win32::Registry::KEY_READ | valuepath.access) do |reg|
      type = [0].pack('L')
      size = [0].pack('L')
      found = reg_query_value_ex_a.call(reg.hkey, valuepath.valuename, 0, type, 0, size) == 0
    end
    found
  end

  def flush
    Puppet.debug("Flushing registry value: #{self}")
    return if resource[:ensure] == :absent

    valuepath.hkey.open(valuepath.subkey, Win32::Registry::KEY_ALL_ACCESS | valuepath.access) do |reg|
      ary = to_native(regvalue[:type], regvalue[:data])
      reg.write(valuepath.valuename, ary[0], ary[1])
    end
  end

  def destroy
    Puppet.debug("Destroying registry value: #{self}")

    valuepath.hkey.open(valuepath.subkey, Win32::Registry::KEY_ALL_ACCESS | valuepath.access) do |reg|
      reg.delete_value(valuepath.valuename)
    end
  end

  def type
    regvalue[:type] || :absent
  end

  def type=(value)
    regvalue[:type] = value
  end

  def data
    regvalue[:data] || :absent
  end

  def data=(value)
    regvalue[:data] = value
  end

  def regvalue
    unless @regvalue
      @regvalue = {}
      valuepath.hkey.open(valuepath.subkey, Win32::Registry::KEY_READ | valuepath.access) do |reg|
        type = [0].pack('L')
        size = [0].pack('L')

        if reg_query_value_ex_a.call(reg.hkey, valuepath.valuename, 0, type, 0, size) == 0
          @regvalue[:type], @regvalue[:data] = from_native(reg.read(valuepath.valuename))
        end
      end
    end
    @regvalue
  end

  def valuepath
    @valuepath ||= resource.parameter(:path)
  end

  # convert puppet type and data to native
  def to_native(ptype, pdata)
    # JJM Because the data property is set to :array_matching => :all we
    # should always get an array from Puppet.  We need to convert this
    # array to something usable by the Win API.
    raise Puppet::Error, "Data should be an Array (ErrorID 37D9BBAB-52E8-4A7C-9F2E-D7BF16A59050)" unless pdata.kind_of?(Array)
    ndata =
      case ptype
      when :binary
        pdata.first.scan(/[a-f\d]{2}/i).map{ |byte| [byte].pack('H2') }.join('')
      when :array
        # We already have an array, and the native API write method takes an
        # array, so send it thru.
        pdata
      else
        # Since we have an array, take the first element and send it to the
        # native API which is expecting a scalar.
        pdata.first
      end

    return [name2type(ptype), ndata]
  end

  # convert from native type and data to puppet
  def from_native(ary)
    ntype, ndata = ary

    pdata =
      case type2name(ntype)
      when :binary
        ndata.scan(/./).map{ |byte| byte.unpack('H2')[0]}.join(' ')
      when :array
        # We get the data from the registry in Array form.
        ndata
      else
        ndata
      end

    # JJM Since the data property is set to :array_matching => all we should
    # always give an array to Puppet.  This is why we have the ternary operator
    # I'm not calling .to_a because Ruby issues a warning about the default
    # implementation of to_a going away in the future.
    return [type2name(ntype), pdata.kind_of?(Array) ? pdata : [pdata]]
  end

  def reg_query_value_ex_a
    @@reg_query_value_ex_a ||= Win32API.new('advapi32', 'RegQueryValueEx', 'LPLPPP', 'L')
  end

  # def to_s
  #   "#{valuepath.hkey.keyname}\\#{valuepath.subkey}\\#{valuepath.valuename}"
  # end
end
