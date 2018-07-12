#
#
#
class bamboo (
  Boolean               $manage_user        = true,
  Boolean               $manage_grp         = true,
  Boolean               $manage_db_settings = true,
  Bamboo::Db_type       $db_type            = 'postgresql',
  String                $bamboo_user        = 'bamboo',
  String                $bamboo_grp         = 'bamboo',
  String                $version            = '6.5.1',
  Bamboo::Pathurl       $source_location    = 'https://www.atlassian.com/software/bamboo/downloads/binary',
  Stdlib::Absolutepath  $bamboo_install_dir = '/opt/atlassian/bamboo',
  Stdlib::Absolutepath  $bamboo_data_dir    = '/var/atlassian/application-data/bamboo'
) {

  if $facts['os']['family'] != 'RedHat' {
    fail("This module is only for the RedHat family, not ${facts['os']['family']}")
  }

  contain bamboo::install
  contain bamboo::config
  contain bamboo::service

  Class['bamboo::install'] -> Class['bamboo::config'] -> Class['bamboo::service']

}
