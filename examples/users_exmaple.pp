registry_key { "HKU\\${windows_currentuser_sid}\\Test2":
  ensure => present
}->
registry_value { "HKU\\${windows_currentuser_sid}\\Test2\\Value1":
  ensure => present,
  type => string,
  data => "I like pie"
}