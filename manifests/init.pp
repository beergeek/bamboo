#
#
#
class bamboo (
  Bamboo::Db_type         $db_type               = 'postgresql',
  Bamboo::Memory          $jvm_xms               = '512m',
  Bamboo::Memory          $jvm_xmx               = '1024m',
  Bamboo::Pathurl         $mysql_driver_source   = 'https://dev.mysql.com/get/Downloads/Connector-J',
  Bamboo::Pathurl         $source_location       = 'https://product-downloads.atlassian.com/software/bamboo/downloads',
  Boolean                 $manage_db_settings    = false,
  Boolean                 $manage_grp            = true,
  Boolean                 $manage_user           = true,
  Optional[Stdlib::Fqdn]  $db_host               = 'localhost',
  Optional[String]        $db_name               = undef,
  Optional[String]        $db_password           = undef,
  Optional[String]        $db_user               = undef,
  Optional[String]        $java_args             = undef,
  Optional[String]        $mysql_driver_pkg      = 'mysql-connector-java-8.0.11.tar.gz',
  # $mysql_driver_jar_name must come after $mysql_driver_pkg
  Optional[String]        $mysql_driver_jar_name = basename($mysql_driver_pkg, '.tar.gz'),
  Stdlib::Absolutepath    $bamboo_data_dir       = '/var/atlassian/application-data/bamboo',
  Stdlib::Absolutepath    $bamboo_install_dir    = '/opt/atlassian/bamboo',
  String                  $bamboo_grp            = 'bamboo',
  String                  $bamboo_user           = 'bamboo',
  String                  $db_port               = '5432',
  String                  $version               = '6.5.1',
) {

  if $facts['os']['family'] != 'RedHat' {
    fail("This module is only for the RedHat family, not ${facts['os']['family']}")
  }

  contain bamboo::install
  contain bamboo::config
  contain bamboo::service

  Class['bamboo::install'] -> Class['bamboo::config'] -> Class['bamboo::service']

}
