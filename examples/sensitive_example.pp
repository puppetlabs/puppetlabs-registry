# Example demonstrating Sensitive[String] support in registry::value
# This example shows how to use Sensitive types for sensitive data like passwords

# Create a sensitive password value
$sensitive_password = Sensitive('mysecretpassword123')

# Use the sensitive password in a registry value
registry::value { 'DefaultPassword':
  key  => 'HKLM\Software\MyApp',
  data => $sensitive_password,
  type => 'string',
}

# You can also use it directly inline
registry::value { 'ApiKey':
  key  => 'HKLM\Software\MyApp',
  data => Sensitive('sk-1234567890abcdef'),
  type => 'string',
}

# For array types, you can mix sensitive and non-sensitive values
registry::value { 'MixedArray':
  key  => 'HKLM\Software\MyApp',
  data => ['public_value', Sensitive('secret_value'), 'another_public'],
  type => 'array',
} 