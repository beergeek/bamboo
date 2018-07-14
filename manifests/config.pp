class bamboo::config {

  assert_private()
  
  case $facts['os']['release']['major'] {
    '6': {
      $init_file = 'bamboo.init.pp'
      $script_path = '/etc/init.d/bamboo'
    }
    '7': {
      $init_file = 'bamboo.systemd.epp'
      $script_path = '/etc/systemd/system/bamboo.service'
    }
    default: {
      fail("You OS version is either far too old or far to bleeding edge: ${facts['os']['release']['major']}")
    }
  }

  file_line { 'bamboo_home_dir':
    ensure => present,
    path   => "${bamboo::bamboo_install_dir}/atlassian-bamboo-${bamboo::version}/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties",
    line   => "bamboo.home=${bamboo::bamboo_data_dir}",
  }

  file { 'init_script':
    ensure  => file,
    path    => $script_path,
    owner   => $bamboo::bamboo_user,
    group   => $bamboo::bamboo_grp,
    mode    => '0644',
    content => epp("bamboo/${init_file}", {
      bamboo_user        => $bamboo::bamboo_user,
      bamboo_install_dir => "${bamboo::bamboo_install_dir}/current",
    }),
  }

  if $bamboo::manage_db_settings {
    if $bamboo::db_host == undef or $bamboo::db_user == undef or $bamboo::db_password == undef {
      fail('When `manage_db_settings` is true you must provide `db_host`, `db_user`, and `db_password`')
    }
    if $bamboo::db_port == undef or empty($bamboo::db_port) {
      if $bamboo::db_type == 'mysql' {
        $_db_port = '3306'
      } else {
        $_db_port = '5432'
      }
    } else {
      $_db_port = $bamboo::db_port
    }
  }
}
