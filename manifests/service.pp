class bamboo::service {

  assert_private()

  service { 'bamboo':
    ensure  => running,
    enable  => true,
  }
}
