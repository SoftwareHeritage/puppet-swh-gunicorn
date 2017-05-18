# APT Configuration for gunicorn
class gunicorn::apt_config {
  if $::lsbdistcodename == 'jessie' {
    $pinned_packages = [
      'gunicorn',
      'gunicorn-examples',
      'gunicorn3',
      'python-gunicorn',
      'python3-gunicorn',
    ]

    ::apt::pin {'gunicorn':
      explanation => 'Pin gunicorn and dependencies to backports',
      codename    => 'jessie-backports',
      packages    => $pinned_packages,
      priority    => 990,
    }
  }

}
