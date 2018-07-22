class bamboo::config {

  assert_private()

  File {
    owner   => $bamboo::bamboo_user,
    group   => $bamboo::bamboo_grp,
    mode    => '0644',
  }

  File_line {
    path    => "${bamboo::bamboo_data_dir}/bamboo.cfg.xml",
  }

  if $facts['os']['name'] == 'Amazon' and $facts['os']['release']['major'] == '4' {
    $init_file = 'bamboo.systemd.epp'
    $script_path = '/etc/systemd/system/bamboo.service'
  } elsif $facts['os']['release']['major'] == '6' {
      $init_file = 'bamboo.init.pp'
      $script_path = '/etc/init.d/bamboo'
  } elsif $facts['os']['release']['major'] == '7' {
    $init_file = 'bamboo.systemd.epp'
    $script_path = '/etc/systemd/system/bamboo.service'
  } else {
    fail("You OS version is either far too old or far to bleeding edge: ${facts['os']['name']} ${facts['os']['release']['major']}")
  }

  if $bamboo::db_type == 'mysql' {
    # If RHEL7 it uses MariaDB, which is not supported, but we can skip the check
    # -Dbamboo.upgrade.fail.if.mysql.unsupported=false
    # Set db connection data
    $_java_args = "${bamboo::java_args} -Dbamboo.upgrade.fail.if.mysql.unsupported=false"
    $_db_driver = 'com.mysql.jdbc.Driver'
    $_db_hibernate = 'org.hibernate.dialect.MySQL5InnoDBDialect'
    $_db_url = "jdbc:mysql://${bamboo::db_host}/${bamboo::db_name}?autoReconnect=true"
  } else {
    $_java_args = $bamboo::java_args
    $_db_driver = 'com.mysql.jdbc.Driver'
    $_db_hibernate = 'org.hibernate.dialect.PostgreSQL82Dialect'
    $_db_url = "jdbc:postgresql://${bamboo::db_host}/${bamboo::db_name}?autoReconnect=true"
  }

  # Configure the home/data/app directory for Bamboo
  file_line { 'bamboo_home_dir':
    ensure => present,
    path   => "${bamboo::bamboo_install_dir}/atlassian-bamboo-${bamboo::version}/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties",
    line   => "bamboo.home=${bamboo::bamboo_data_dir}",
  }

  file { 'base_config':
    ensure  => file,
    path    => "${bamboo::bamboo_data_dir}/bamboo.cfg.xml",
    source  => 'puppet:///modules/bamboo/bamboo.cfg.xml',
    replace => false,
  }

  # Startup/Shutdown script
  file { 'init_script':
    ensure  => file,
    path    => $script_path,
    mode    => '0744',
    content => epp("bamboo/${init_file}", {
      bamboo_user        => $bamboo::bamboo_user,
      bamboo_install_dir => "${bamboo::bamboo_install_dir}/current",
    }),
  }

  if $bamboo::manage_db_settings {
    # Check if we have the required info
    if $bamboo::db_name == undef or $bamboo::db_host == undef or $bamboo::db_user == undef or $bamboo::db_password == undef {
      fail('When `manage_db_settings` is true you must provide `db_name`, `db_host`, `db_user`, and `db_password`')
    }
    # Determine if port is supplied, if not assume default port for database type
    if $bamboo::db_port == undef or empty($bamboo::db_port) {
      if $bamboo::db_type == 'mysql' {
        $_db_port = '3306'
      } else {
        $_db_port = '5432'
      }
    } else {
      $_db_port = $bamboo::db_port
    }

    # If MySQL we need the driver and set
    if $bamboo::db_type == 'mysql' {
      archive { "/tmp/${bamboo::mysql_driver_pkg}":
        ensure          => present,
        extract         => true,
        extract_command => "tar -zxf %s --strip-components 1 --exclude='lib*' */${bamboo::mysql_driver_jar_name}",
        extract_path    => "${bamboo::bamboo_install_dir}/atlassian-bamboo-${bamboo::version}/lib",
        source          => "${bamboo::mysql_driver_source}/${bamboo::mysql_driver_pkg}",
        creates         => "${bamboo::bamboo_install_dir}/atlassian-bamboo-${bamboo::version}/lib/${bamboo::mysql_driver_jar_name}",
        cleanup         => true,
        user            => $bamboo::bamboo_user,
        group           => $bamboo::bamboo_grp,
      }
    }

    # Database connector config
    file_line { 'db_driver':
      ensure  => present,
      line    => "    <property name=\"hibernate.connection.driver_class\">${_db_driver}</property>",
      match   => '^( |\t)*<property name\="hibernate.connection.driver_class">',
      after   => '^( |\t)*<property name\="bamboo.jms.broker.uri">',
      require => File['base_config'],
    }

    file_line { 'db_password':
      ensure  => present,
      line    => "    <property name=\"hibernate.connection.password\">${bamboo::db_password}</property>",
      match   => '^( |\t)*<property name\="hibernate.connection.password">',
      after   => '^( |\t)*<property name\="hibernate.connection.driver_class">',
      require => File_line['db_driver'],
    }

    file_line { 'db_url':
      ensure  => present,
      line    => "    <property name=\"hibernate.connection.url\">${_db_url}</property>",
      match   => '^( |\t)*<property name\="hibernate.connection.url">',
      after   => '^( |\t)*<property name\="hibernate.connection.password">',
      require => File_line['db_password'],
    }

    file_line { 'db_user':
      ensure  => present,
      line    => "    <property name=\"hibernate.connection.username\">${bamboo::db_user}</property>",
      match   => '^( |\t)*<property name\="hibernate.connection.username">',
      after   => '^( |\t)*<property name\="hibernate.connection.url">',
      require => File_line['db_url'],
    }

    file_line { 'db_dialect':
      ensure  => present,
      line    => "    <property name=\"hibernate.dialect\">${_db_hibernate}</property>",
      match   => '^( |\t)*<property name\="hibernate.dialect">',
      after   => '^( |\t)*<property name\="hibernate.connection.username">',
      require => File_line['db_user'],
    }
  }

  file { 'java_args':
    ensure  => file,
    path    => "${bamboo::bamboo_install_dir}/atlassian-bamboo-${bamboo::version}/bin/setenv.sh",
    content => epp('bamboo/setenv.sh.epp', {
      java_args => $_java_args,
      java_xms  => $bamboo::jvm_xms,
      java_xmx  => $bamboo::jvm_xmx,
    })
  }
}
