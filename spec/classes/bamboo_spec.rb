require 'spec_helper'

describe 'bamboo' do
  let :facts do
    {
      os: { 'family' => 'RedHat', 'release' => { 'major' => '7' } },
      osfamily: 'RedHat',
      operatingsystem: 'RedHat',
    }
  end

  context 'With defaults' do
    it do
      is_expected.to contain_class('bamboo::install')
      is_expected.to contain_class('bamboo::config')
      is_expected.to contain_class('bamboo::service')
    end

    describe 'bamboo::install' do
      it do
        is_expected.to contain_user('bamboo').with(
          'ensure'      => 'present',
          'gid'         => 'bamboo',
          'managehome'  => true,
          'shell'       => '/sbin/nologin',
        )
      end

      it do
        is_expected.to contain_group('bamboo').with(
          'ensure'  => 'present',
        )
      end

      it do
        is_expected.to contain_file('/opt/atlassian/bamboo').with(
          'ensure'  => 'directory',
          'owner'   => 'bamboo',
          'group'   => 'bamboo',
          'mode'    => '0755',
        )
      end

      it do
        is_expected.to contain_file('/var/atlassian/application-data/bamboo').with(
          'ensure'  => 'directory',
          'owner'   => 'bamboo',
          'group'   => 'bamboo',
          'mode'    => '0755',
        )
      end

      it do
        is_expected.to contain_archive('/tmp/atlassian-bamboo-6.5.1.tar.gz').with(
          'ensure'        => 'present',
          'extract'       => true,
          'extract_path'  => '/opt/atlassian/bamboo',
          'source'        => 'https://product-downloads.atlassian.com/software/bamboo/downloads/atlassian-bamboo-6.5.1.tar.gz',
          'creates'       => '/opt/atlassian/bamboo/atlassian-bamboo-6.5.1',
          'cleanup'       => true,
          'user'          => 'bamboo',
          'group'         => 'bamboo',
        ).that_requires('File[/opt/atlassian/bamboo]')
      end

      it do
        is_expected.to contain_file('/opt/atlassian/bamboo/current').with(
          'ensure'  => 'link',
          'target'  => '/opt/atlassian/bamboo/atlassian-bamboo-6.5.1',
        )
      end

      it do
        is_expected.to contain_file('/etc/init.d/bamboo').with(
          'ensure'  => 'file',
          'owner'   => 'bamboo',
          'group'   => 'bamboo',
          'mode'    => '0744',
        ).with_content(/bamboo_dir=\/opt\/atlassian\/bamboo\/current\nuser=bamboo/)
      end
    end

    describe 'bamboo::config' do
      it do
        is_expected.to contain_file_line('bamboo_home_dir').with(
          'ensure'  => 'present',
          'path'    => '/opt/atlassian/bamboo/atlassian-bamboo-6.5.1/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties',
          'line'    => 'bamboo.home=/var/atlassian/application-data/bamboo',
        )
      end
    end

    describe 'bamboo::service' do
      it do
        is_expected.to contain_service('bamboo').with(
          'ensure' => 'running',
          'enable' => true,
        )
      end
    end
  end

  context 'bamboo with MySQL database' do
    let :params do
      {
        manage_db_settings: true,
        db_host: 'mysql0.puppet.vm',
        db_user: 'bamboo',
        db_port: '3306',
        db_password: 'password123',
      }
    end

    describe 'bamboo::config' do
      it do
        is_expected.to contain_file('db_config').with(
          'ensure' => 'file',
          'path'   => '/etc/systemd/system/bamboo.service',
          'owner'  => 'bamboo',
          'group'  => 'bamboo',
          'mode'   => '0644',
        )
      end
    end
  end
end
