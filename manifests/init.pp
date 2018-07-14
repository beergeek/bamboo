#
#
#
class bamboo (
  Bamboo::Db_type         $db_type            = 'postgresql',
  Bamboo::Pathurl         $source_location    = 'https://product-downloads.atlassian.com/software/bamboo/downloads',
  Boolean                 $manage_db_settings = false,
  Boolean                 $manage_grp         = true,
  Boolean                 $manage_user        = true,
  Optional[Stdlib::Fqdn]  $db_host            = undef,
  Optional[String]        $db_name            = undef,
  Optional[String]        $db_password        = undef,
  Optional[String]        $db_user            = undef,
  String                  $db_port            = '5432',
  Stdlib::Absolutepath    $bamboo_data_dir    = '/var/atlassian/application-data/bamboo',
  Stdlib::Absolutepath    $bamboo_install_dir = '/opt/atlassian/bamboo',
  String                  $bamboo_grp         = 'bamboo',
  String                  $bamboo_user        = 'bamboo',
  String                  $version            = '6.5.1',
) {

  if $facts['os']['family'] != 'RedHat' {
    fail("This module is only for the RedHat family, not ${facts['os']['family']}")
  }

  contain bamboo::install
  contain bamboo::config
  contain bamboo::service

  Class['bamboo::install'] -> Class['bamboo::config'] -> Class['bamboo::service']

}
