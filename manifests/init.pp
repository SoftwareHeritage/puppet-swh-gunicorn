class gunicorn {
  $packages = ['gunicorn3']

  include gunicorn::apt_config

  package {$packages:
    ensure => installed,
  }

  ::systemd::unit_file {'gunicorn.service':
    source => 'puppet:///modules/gunicorn/gunicorn.service',
  } ~> service {'gunicorn':
      ensure  => running,
      enable  => true,
      require => [
        Package[$packages],
      ],
    }


  file {['/etc/gunicorn', '/etc/gunicorn/instances']:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    recurse => true,
    purge   => true,
  }

  file {'/etc/tmpfiles.d/gunicorn.conf':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/gunicorn/gunicorn.tmpfiles',
    notify => Exec['systemd-tmpfiles-update-gunicorn'],
  }

  file {'/etc/gunicorn/logconfig.ini':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/gunicorn/logconfig.ini',
  }

  exec {'systemd-tmpfiles-update-gunicorn':
    path        => '/sbin:/usr/sbin:/bin:/usr/bin',
    command     => 'systemd-tmpfiles --create /etc/tmpfiles.d/gunicorn.conf',
    refreshonly => true,
    require     => File['/etc/tmpfiles.d/gunicorn.conf']
  }
}
