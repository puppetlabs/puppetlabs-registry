# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/registry_value'

describe Puppet::Type.type(:registry_value).provider(:registry) do
  let(:catalog) { Puppet::Resource::Catalog.new }
  let(:type) { Puppet::Type.type(:registry_value) }
  let(:instance) { instance_double(Win32::Registry) }

  puppet_key = 'SOFTWARE\\Puppet Labs'
  subkey_name = 'PuppetRegProviderTest'

  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    if Puppet.features.microsoft_windows?
      Win32::Registry::HKEY_LOCAL_MACHINE.create("#{puppet_key}\\#{subkey_name}",
                                                 Win32::Registry::KEY_ALL_ACCESS |
                                                 PuppetX::Puppetlabs::Registry::KEY_WOW64_64KEY)
    end
  end

  before(:each) do
    skip('Not on Windows platform') unless Puppet.features.microsoft_windows?
    # problematic Ruby codepath triggers a conversion of UTF-16LE to
    # a local codepage which can totally break when that codepage has no
    # conversion from the given UTF-16LE characters to local codepage
    # a prime example is that IBM437 has no conversion from a Unicode en-dash

    expect(instance).to receive(:export_string).never

    expect(instance).to receive(:delete_value).never
    expect(instance).to receive(:delete_key).never

    if RUBY_VERSION >= '2.1'
      # also, expect that we're not using Rubys each_key / each_value which exhibit bad behavior
      expect(instance).to receive(:each_key).never
      expect(instance).to receive(:each_value).never

      # this covers []= write_s write_i and write_bin
      expect(instance).to receive(:write).never
    end

    # rubocop:enable RSpec/ExpectInHook
  end

  after(:all) do # rubocop:disable RSpec/BeforeAfterAll
    if Puppet.features.microsoft_windows?
      # Ruby 2.1.5 has bugs with deleting registry keys due to using ANSI
      # character APIs, but passing wide strings to them (facepalm)
      # https://github.com/ruby/ruby/blob/v2_1_5/ext/win32/lib/win32/registry.rb#L323-L329
      # therefore, use our own code instead of hklm.delete_value

      # NOTE: registry_value tests unfortunately depend on registry_key type
      # otherwise, there would be a bit of Win32 API code here
      reg_key = Puppet::Type.type(:registry_key).new(path: "hklm\\#{puppet_key}\\#{subkey_name}",
                                                     provider: :registry)
      reg_key.provider.destroy
    end
  end

  describe '#exists?' do
    it 'returns true for a well known hive' do
      reg_value = type.new(title: 'hklm\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareType', provider: described_class.name)
      reg_value.provider.exists?.should be true
    end

    it 'returns true for a well known hive with mixed case name' do
      reg_value = type.new(title: 'hklm\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareType'.upcase, provider: described_class.name)
      reg_value.provider.exists?.should be true
    end

    it 'returns true for a well known hive with double backslash' do
      reg_value = type.new(title: 'hklm\SOFTWARE\Microsoft\Windows NT\CurrentVersion\\\\SoftwareType', provider: described_class.name)
      reg_value.provider.exists?.should be true
    end

    it 'returns true for a well known hive with mixed case name with double backslash' do
      reg_value = type.new(title: 'hklm\SOFTWARE\Microsoft\Windows NT\CurrentVersion\\\\SoftwareType'.upcase, provider: described_class.name)
      reg_value.provider.exists?.should be true
    end

    it 'returns false for a bogus hive/path' do
      reg_value = type.new(path: 'hklm\foobar5000', catalog: catalog, provider: described_class.name)
      reg_value.provider.exists?.should be false
    end
  end

  describe '#regvalue' do
    it 'returns a valid string for a well known key' do
      reg_value = type.new(path: 'hklm\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRoot', provider: described_class.name)
      reg_value.provider.data.should eq [ENV['SystemRoot']]
      reg_value.provider.type.should eq :string
    end

    it 'returns a string of lowercased hex encoded bytes' do
      reg = described_class.new
      _type, data = reg.from_native([3, "\u07AD"])
      data.should eq ['de ad']
    end

    it 'left pads binary strings' do
      reg = described_class.new
      _type, data = reg.from_native([3, "\x1"])
      data.should eq ['01']
    end
  end

  describe '#destroy' do
    let(:default_path) { _path = "hklm\\#{puppet_key}\\#{subkey_name}\\" }
    let(:valuename) { SecureRandom.uuid }
    let(:path) { "hklm\\#{puppet_key}\\#{subkey_name}\\#{valuename}" }

    def create_and_destroy(path, reg_type, data)
      reg_value = type.new(path: path,
                           type: reg_type,
                           data: data,
                           provider: described_class.name)
      already_exists = reg_value.provider.exists?
      already_exists.should be_falsey
      # something has gone terribly wrong here, pull the ripcord
      raise if already_exists

      reg_value.provider.create
      reg_value.provider.exists?.should be true
      expect(reg_value.provider.data).to eq([data].flatten)

      reg_value.provider.destroy
      reg_value.provider.exists?.should be false
    end

    context 'with a valuename containing a middle double backslash' do
      let(:valuename) { SecureRandom.uuid.insert(5, '\\\\') }
      let(:path) { "hklm\\#{puppet_key}\\#{subkey_name}\\\\#{valuename}" }

      it 'can destroy a randomly created REG_SZ value' do
        create_and_destroy(path, :string, SecureRandom.uuid)
      end
    end

    context 'with a valuename containing a leading double backslash' do
      let(:valuename) { '\\\\' + SecureRandom.uuid }
      let(:path) { "hklm\\#{puppet_key}\\#{subkey_name}\\\\#{valuename}" }

      it 'can destroy a randomly created REG_SZ value' do
        create_and_destroy(path, :string, SecureRandom.uuid)
      end
    end

    context 'with a valuename containing a trailing double backslash' do
      let(:valuename) { SecureRandom.uuid + '\\\\' }
      let(:path) { "hklm\\#{puppet_key}\\#{subkey_name}\\\\#{valuename}" }

      it 'can destroy a randomly created REG_SZ value' do
        create_and_destroy(path, :string, SecureRandom.uuid)
      end
    end

    context 'with a valuename of a backslash' do
      let(:valuename) { '\\' }
      let(:path) { "hklm\\#{puppet_key}\\#{subkey_name}\\\\#{valuename}" }

      it 'can destroy a randomly created REG_SZ value' do
        create_and_destroy(path, :string, SecureRandom.uuid)
      end
    end

    context 'with a valuename containing a backslash' do
      let(:valuename) { SecureRandom.uuid.insert(5, '\\') }
      let(:path) { "hklm\\#{puppet_key}\\#{subkey_name}\\\\#{valuename}" }

      it 'can destroy a randomly created REG_SZ value' do
        create_and_destroy(path, :string, SecureRandom.uuid)
      end

      it 'can destroy a randomly created REG_EXPAND_SZ value' do
        create_and_destroy(path, :expand, "#{SecureRandom.uuid} system root is %SystemRoot%")
      end

      it 'can destroy a randomly created REG_BINARY value' do
        create_and_destroy(path, :binary, '01 01 10 10')
      end

      it 'can destroy a randomly created REG_DWORD value' do
        create_and_destroy(path, :dword, rand(2**32 - 1))
      end

      it 'can destroy a randomly created REG_QWORD value' do
        create_and_destroy(path, :qword, rand(2**64 - 1))
      end

      it 'can destroy a randomly created REG_MULTI_SZ value' do
        create_and_destroy(path, :array, [SecureRandom.uuid, SecureRandom.uuid])
      end
    end

    it 'can destroy a randomly created default REG_SZ value' do
      create_and_destroy(default_path, :string, SecureRandom.uuid)
    end

    it 'can destroy a randomly created REG_SZ value' do
      create_and_destroy(path, :string, SecureRandom.uuid)
    end

    it 'can destroy a randomly created REG_EXPAND_SZ value' do
      create_and_destroy(path, :expand, "#{SecureRandom.uuid} system root is %SystemRoot%")
    end

    it 'can destroy a randomly created REG_BINARY value' do
      create_and_destroy(path, :binary, '01 01 10 10')
    end

    it 'can destroy a randomly created REG_DWORD value' do
      create_and_destroy(path, :dword, rand(2**32 - 1))
    end

    it 'can destroy a randomly created REG_QWORD value' do
      create_and_destroy(path, :qword, rand(2**64 - 1))
    end

    it 'can destroy a randomly created REG_MULTI_SZ value' do
      create_and_destroy(path, :array, [SecureRandom.uuid, SecureRandom.uuid])
    end
  end

  context 'when writing numeric values' do
    let(:path) { "hklm\\#{puppet_key}\\#{subkey_name}\\#{SecureRandom.uuid}" }

    after(:each) do
      reg_value = type.new(path: path, provider: described_class.name)

      reg_value.provider.destroy
    end

    def write_and_read_value(path, reg_type, value)
      reg_value = type.new(path: path,
                           type: reg_type,
                           data: value,
                           provider: described_class.name)

      reg_value.provider.create
      expect(reg_value.provider).to be_exists
      expect(reg_value.provider.type).to eq(reg_type)

      written = reg_value.provider.data.first
      expect(written).to eq(value)
    end

    # values chosen at 1 bit past previous byte boundary
    [0xFF + 1, 0xFFFF + 1, 0xFFFFFF + 1, 0xFFFFFFFF].each do |value|
      it 'properly round-trips written values by converting endianness properly - 1' do
        write_and_read_value(path, :dword, value)
        write_and_read_value(path, :qword, value)
      end
    end

    [0xFFFFFFFFFF + 1, 0xFFFFFFFFFFFF + 1, 0xFFFFFFFFFFFFFF + 1, 0xFFFFFFFFFFFFFFFF].each do |value|
      it 'properly round-trips written values by converting endianness properly - 2' do
        write_and_read_value(path, :qword, value)
      end
    end
  end

  context 'when reading non-ASCII values' do
    ENDASH_UTF_8 = [0xE2, 0x80, 0x93].freeze
    ENDASH_UTF_16 = [0x2013].freeze
    TM_UTF_8 = [0xE2, 0x84, 0xA2].freeze
    TM_UTF_16 = [0x2122].freeze

    let(:guid) { SecureRandom.uuid }

    after(:each) do
      # Ruby 2.1.5 has bugs with deleting registry keys due to using ANSI
      # character APIs, but passing wide strings to them (facepalm)
      # https://github.com/ruby/ruby/blob/v2_1_5/ext/win32/lib/win32/registry.rb#L323-L329
      # therefore, use our own code instead of hklm.delete_value

      reg_value = type.new(path: "hklm\\#{puppet_key}\\#{subkey_name}\\#{guid}",
                           provider: described_class.name)

      reg_value.provider.destroy
      reg_value.provider.exists?.should be_falsey
    end

    # proof that there is no conversion to local encodings like IBM437
    it 'will return a UTF-8 string from a REG_SZ registry value (written as UTF-16LE)' do
      skip('Not on Windows platform with Ruby version greater than or equal to 2.1') unless Puppet.features.microsoft_windows? && RUBY_VERSION >= '2.1'

      # create a UTF-16LE byte array representing "–™"
      utf_16_bytes = ENDASH_UTF_16 + TM_UTF_16
      utf_16_str = utf_16_bytes.pack('s*').force_encoding(Encoding::UTF_16LE)

      # and it's UTF-8 equivalent bytes
      utf_8_bytes = ENDASH_UTF_8 + TM_UTF_8
      utf_8_str = utf_8_bytes.pack('c*').force_encoding(Encoding::UTF_8)

      reg_value = type.new(path: "hklm\\#{puppet_key}\\#{subkey_name}\\#{guid}",
                           type: :string,
                           data: utf_16_str,
                           provider: described_class.name)

      already_exists = reg_value.provider.exists?
      already_exists.should be_falsey

      reg_value.provider.create
      reg_value.provider.exists?.should be true

      reg_value.provider.data.length.should eq 1
      reg_value.provider.type.should eq :string

      # The UTF-16LE string written should come back as the equivalent UTF-8
      written = reg_value.provider.data.first
      written.should eq(utf_8_str)
      written.encoding.should eq(Encoding::UTF_8)
    end
  end
end
