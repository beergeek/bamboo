#
#
#
class bamboo::install () {

  assert_private()

  if $bamboo::manage_user {
    user { $bamboo::bamboo_user:
      ensure      => present,
      gid         => $bamboo::bamboo_grp,
      managehome  => true,
      shell       => '/sbin/nologin',
    }
  }

  if $bamboo::manage_grp {
    group { $bamboo::bamboo_grp:
    ensure => present,
    }
  }

  file { $bamboo::bamboo_install_dir:
    ensure  => directory,
    owner   => $bamboo::bamboo_user,
    group   => $bamboo::bamboo_grp,
    mode    => '0755',
  }

  archive { "/tmp/atlassian-bamboo-${bamboo::version}.tar.gz":
    ensure        => present,
    extract       => true,
    extract_path  => $bamboo::bamboo_install_dir,
    source        => "${bamboo::source_location}/atlassian-bamboo-${bamboo::version}.tar.gz",
    creates       => "${bamboo::bamboo_install_dir}/atlassian-bamboo-${bamboo::version}",
    cleanup       => true,
    user          => $bamboo::bamboo_user,
    group         => $bamboo::bamboo_grp,
    require       => File[$bamboo::bamboo_install_dir],
  }

  file { "${bamboo::bamboo_install_dir}/current":
    ensure  => link,
    target  => "${bamboo::bamboo_install_dir}/atlassian-bamboo-${bamboo::version}",
  }

  file { "/etc/init.d/bamboo":
    ensure  => file,
    owner   => $bamboo::bamboo_user,
    group   => $bamboo::bamboo_grp,
    mode    => '0744',
    content => epp("bamboo/bamboo.init.epp", {
      bamboo_install_dir => $bamboo::bamboo_install_dir,
      bamboo_user        => $bamboo::bamboo_user,
    }),
  }
}
