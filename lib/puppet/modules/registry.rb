require 'pathname'
# JJM WORK_AROUND
# explicitly require files without relying on $LOAD_PATH until #14073 is fixed.
# https://projects.puppetlabs.com/issues/14073 is fixed.
require Pathname.new(__FILE__).dirname.expand_path

module Puppet::Modules::Registry
  # For 64-bit OS, use 64-bit view. Ignored on 32-bit OS
  KEY_WOW64_64KEY = 0x100 unless defined? KEY_WOW64_64KEY
  # For 64-bit OS, use 32-bit view. Ignored on 32-bit OS
  KEY_WOW64_32KEY = 0x200 unless defined? KEY_WOW64_32KEY
end
