class bamboo::config {

  assert_private()

  file_line { 'bamboo_home_dir':
    ensure  => present,
    path    => "${bamboo::bamboo_install_dir}/atlassian-bamboo-${bamboo::version}/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties",
    line    => "bamboo.home=${bamboo::bamboo_data_dir}",
  }

  if $manage_db_settings {
    if $db_host == undef or $db_user == undef or $db_password == undef {
      fail('When `manage_db_settings` is true you must provide `db_host`, `db_user` and `db_password`')
    }

    file_line
  }
}
