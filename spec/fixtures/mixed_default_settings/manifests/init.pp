class mixed_default_settings {
  registry_value { 'hklm\Software\foo\\':
    ensure => present,
    type   => string,
    data   => 'default',
  }

  registry_value { 'hklm\Software\foo':
    ensure => present,
    type   => string,
    data   => 'nondefault',
  }
}
