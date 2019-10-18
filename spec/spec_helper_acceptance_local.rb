def random_string(length)
  chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
  str = ''
  1.upto(length) { |_i| str << chars[rand(chars.size - 1)] }
  str
end

def is_x64?
  host_inventory['facter']['os']['architecture'] == 'x64'
end
