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
    end

    describe 'bamboo::config' do
      it do
        is_expected.to contain_file_line('bamboo_home_dir').with(
          'ensure'  => 'present',
          'path'    => '/opt/atlassian/bamboo/atlassian-bamboo-6.5.1/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties',
          'line'    => 'bamboo.home=/var/atlassian/application-data/bamboo',
        )
      end

      it do
        is_expected.to contain_file('init_script').with(
          'ensure' => 'file',
          'path'   => '/etc/systemd/system/bamboo.service',
          'owner'  => 'bamboo',
          'group'  => 'bamboo',
          'mode'   => '0744',
        ).with_content(/User=bamboo\nExecStart=\/opt\/atlassian\/bamboo\/current\/bin\/start-bamboo.sh\nExecStop=\/opt\/atlassian\/bamboo\/current\/bin\/stop-bamboo.sh/)
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
        db_type: 'mysql',
        db_host: 'mysql0.puppet.vm',
        db_name: 'bamboodb',
        db_user: 'bamboo',
        db_password: 'password123',
      }
    end

    describe 'bamboo::config' do
      it do
        is_expected.to contain_archive('/tmp/mysql-connector-java-8.0.11.tar.gz').with(
          'ensure'          => 'present',
          'extract'         => true,
          'extract_command' => "tar -zxf %s --exclude='lib*' mysql*.jar",
          'extract_path'    => '/opt/atlassian/bamboo/atlassian-bamboo-6.5.1/lib',
          'source'          => 'https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.11.tar.gz',
          'creates'         => '/opt/atlassian/bamboo/atlassian-bamboo-6.5.1/lib/mysql-connector-java-8.0.11',
          'cleanup'         => true,
          'user'            => 'bamboo',
          'group'           => 'bamboo',
        )
      end

      it do
        is_expected.to contain_file('java_args').with(
          'ensure'  => 'file',
          'path'    => '/opt/atlassian/bamboo/atlassian-bamboo-6.5.1/bin/setenv.sh',
          'owner'  => 'bamboo',
          'group'  => 'bamboo',
          'mode'   => '0644',
        ).with_content(/: \$\{JVM_SUPPORT_RECOMMENDED_ARGS:=" -Dbamboo\.upgrade\.fail\.if\.mysql\.unsupported=false"\}/)
      end

      it do
        is_expected.to contain_file_line('db_driver').with(
          'ensure'  => 'present',
          'path'    => '/var/atlassian/application-data/bamboo/bamboo.cfg.xml',
          'line'    => "\t\t\t<property name=\"hibernate.connection.driver_class\">com.mysql.jdbc.Driver</property>",
          'match'   => '\s*<property name="hibernate.connection.driver_class">',
        )
      end

      it do
        is_expected.to contain_file_line('db_hibernate').with(
          'ensure'  => 'present',
          'path'    => '/var/atlassian/application-data/bamboo/bamboo.cfg.xml',
          'line'    => "\t\t\t<property name=\"hibernate.dialect\">org.hibernate.dialect.MySQL5InnoDBDialect</property>",
          'match'   => '\\s*<property name="hibernate.dialect">',
        )
      end

      it do
        is_expected.to contain_file_line('db_password').with(
          'ensure'  => 'present',
          'path'    => '/var/atlassian/application-data/bamboo/bamboo.cfg.xml',
          'line'    => "\t\t\t<property name=\"hibernate.connection.password\">password123</property>",
          'match'   => '\\s*<property name="hibernate.connection.password">',
        )
      end

      it do
        is_expected.to contain_file_line('db_user').with(
          'ensure'  => 'present',
          'path'    => '/var/atlassian/application-data/bamboo/bamboo.cfg.xml',
          'line'    => "\t\t\t<property name=\"hibernate.connection.username\">bamboo</property>",
          'match'   => '\\s*<property name="hibernate.connection.username">',
        )
      end

      it do
        is_expected.to contain_file_line('db_url').with(
          'ensure'  => 'present',
          'path'    => '/var/atlassian/application-data/bamboo/bamboo.cfg.xml',
          'line'    => "\t\t\t<property name=\"hibernate.connection.url\">jdbc:mysql://mysql0.puppet.vm/bamboodb?autoReconnect=true</property>",
          'match'   => '\\s*<property name="hibernate.connection.url">',
        )
      end
    end
  end
end
