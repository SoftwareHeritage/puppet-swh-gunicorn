# == Defined Type: gunicorn::instance
#
# gunicorn::instance defines an instance of gunicorn
#
# === Parameters
#
# [*ensure*]
#   Whether the instance should be enabled, present (but disabled) or absent.
#
# [*executable*]
#   The wsgi callable to pass to gunicorn
#
# [*settings*]
#   a hash of settings for the given site.
#
# === Examples
#
#  gunicorn::instance {'foo':
#    ensure      => enabled,
#    executable  => 'foo.wsgi:app'
#    user        => 'foouser',
#    group       => 'foogroup',
#    config_mode => 0644
#    settings    => {
#      plugin              => 'python3',
#      protocol            => $uwsgi_protocol,
#      socket              => $uwsgi_listen_address,
#      workers             => $uwsgi_workers,
#      max_requests        => $uwsgi_max_requests,
#      max_requests_delta  => $uwsgi_max_requests_delta,
#      worker_reload_mercy => $uwsgi_reload_mercy,
#      reload_mercy        => $uwsgi_reload_mercy,
#      uid                 => $user,
#      gid                 => $user,
#      module              => 'swh.storage.api.server',
#      callable            => 'run_from_webserver',
#    }
#  }
#
# === Authors
#
# Nicolas Dandrimont <nicolas@dandrimont.eu>
#
# === Copyright
#
# Copyright 2017 The Software Heritage developers
#
define gunicorn::instance (
  $executable,
  $user = 'root',
  $group = 'root',
  $ensure = 'enabled',
  $config_mode = '0644',
  $working_dir = undef,
  $log_only_errors = true,
  $settings = {}
) {
  $config_file = "/etc/gunicorn/instances/${name}.cfg"
  $service_name = "gunicorn-${name}"
  $service_file = "/etc/systemd/system/${service_name}.service"
  $tmpfiles_file = "/etc/tmpfiles.d/${service_name}.conf"
  $runtime_dir = "/run/gunicorn/${name}"

  if $working_dir {
    $working_dir_override = $working_dir
  } else {
    $working_dir_override = $runtime_dir
  }

  if $log_only_errors {
    $log_only_errors_str = 'True'
  } else {
    $log_only_errors_str = 'False'
  }

  case $ensure {
    default: { err("Unknown value ensure => ${ensure}.") }
    'enabled', 'present': {

      # Uses variables:
      #  - $settings
      #  - $name
      #  - $log_only_errors_str
      file {$config_file:
        ensure  => present,
        owner   => $user,
        group   => $group,
        mode    => $config_mode,
        content => template('gunicorn/gunicorn-instance.cfg.erb'),
        notify  => Service[$service_name],
      }

      # Uses variables:
      #  - $config_file
      #  - $executable
      #  - $group
      #  - $name
      #  - $runtime_dir
      #  - $user
      #  - $working_dir_override
      file {$service_file:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('gunicorn/gunicorn-instance.cfg.erb'),
        notify  => Exec['systemd-daemon-reload'],
      }

      # Uses variables:
      #  - $group
      #  - $name
      #  - $runtime_dir
      #  - $user
      file {$tmpfiles_file:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('gunicorn/gunicorn-instance.tmpfiles.erb'),
        notify  => Exec["systemd-tmpfiles-update-${service_name}"],
      }

      exec {"systemd-tmpfiles-update-${service_name}":
        path        => '/sbin:/usr/sbin:/bin:/usr/bin',
        command     => "systemd-tmpfiles --create ${tmpfiles_file}",
        refreshonly => true,
        require     => File[$tmpfiles_file]
      }

      $service_enable = $ensure ? {
        'enabled' => true,
        'present' => undef,
      }

      service {$service_name:
        ensure  => 'running',
        enable  => $service_enable,
        restart => "/bin/systemctl reload ${service_name}.service",
      }
    }

    'absent': {
      file {[$tmpfiles_file, $service_file]:
        ensure => 'absent'
      }
    }
  }
}

