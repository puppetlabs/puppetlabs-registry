class test_registry::titles_and_aliases {
  registry_value { 'HKLM\Software\foo1':
    value_name => 'Value1',
    data       => "Should be HKLM\Software\foo1\Value1",
  }

  registry_value { 'HKLM\Software\foo2':
    value_name => 'Value1',
    data       => "Should be HKLM\Software\foo2\Value1",
  }

  registry_value { 'foo3':
    path       =>'HKLM\Software\foo3':
    value_name => 'Value1',
    data       => "Should be HKLM\Software\foo3\Value1",
  }
}
