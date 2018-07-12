class bamboo::config {

  file_line { 'bamboo_home_dir':
    ensure  => present,
    path    => "${bamboo::bamboo_install_dir}/atlassian-bamboo-${bamboo::version}/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties",
    line    => "bamboo.home=${bamboo::bamboo_data_dir}",
  }
}
