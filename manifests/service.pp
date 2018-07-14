class bamboo::service {

  service { 'bamboo':
    ensure => running,
    enable => true,
  }
}
