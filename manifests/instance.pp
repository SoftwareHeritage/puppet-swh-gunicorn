# == Defined Type: gunicorn::instance
#
# gunicorn::instance defines an instance of gunicorn
#
# === Parameters
#
# [*ensure*]
#   Whether the instance should be enabled, present (but disabled) or absent.
#
# [*environment*]
#   A hash of environment variables to start the service with.
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
#    environment => {
#      FOOENV => 'foovar',
#    }
#    executable  => 'foo.wsgi:app'
#    user        => 'foouser',
#    group       => 'foogroup',
#    config_mode => 0644,
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
  $config_base_module = undef,
  $log_only_errors = true,
  $settings = {},
  $environment = {}
) {
  $config_file = "/etc/gunicorn/instances/${name}.cfg"
  $service_name = "gunicorn-${name}"
  $unit_name = "${service_name}.service"
  $tmpfile_name = "${service_name}.conf"
  $runtime_dir = "gunicorn/${name}"

  if $working_dir {
    $working_dir_override = $working_dir
  } else {
    $working_dir_override = "/run/$runtime_dir"
  }

  if $log_only_errors {
    $log_only_errors_str = 'True'
  } else {
    $log_only_errors_str = 'False'
  }

  case $ensure {
    default: { err("Unknown value ensure => ${ensure}.") }
    'enabled', 'present': {

      include ::gunicorn

      # Uses variables:
      #  - $settings
      #  - $name
      #  - $log_only_errors_str
      #  - $config_base_module
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
      #  - $environment
      #  - $executable
      #  - $group
      #  - $name
      #  - $runtime_dir
      #  - $user
      #  - $working_dir_override
      ::systemd::unit_file {$unit_name:
        ensure  => present,
        content => template('gunicorn/gunicorn-instance.service.erb'),
      } ~> Service[$service_name]

      ::systemd::tmpfile {$tmpfile_name:
        ensure  => absent,
      }

      $service_enable = $ensure ? {
        'enabled' => true,
        'present' => undef,
      }

      service {$service_name:
        ensure  => 'running',
        enable  => $service_enable,
        restart => "/bin/systemctl reload ${service_name}.service",
        require => [
          File[$config_file],
        ],
      }
    }

    'absent': {
      ::systemd::unit_file {$unit_name:
        ensure => absent,
      }
      ::systemd::tmpfile {$tmpfile_name:
        ensure  => absent,
      }
      file {$config_file:
        ensure  => absent,
      }
    }
  }
}

