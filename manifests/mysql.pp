# 10-auth.conf
# dovecot-sql.conf.ext
class dovecot::mysql (
  $dbname              = 'mails',
  $dbpassword          = 'admin',
  $dbusername          = 'pass',
  $dbhost              = 'localhost',
  $dbport              = 3306,
  $default_pass_scheme = 'CRYPT',
  $mailstorepath       = '/srv/vmail/',
  $sqlconftemplate     = 'dovecot/dovecot-sql.conf.ext',
) {
  $driver = 'mysql'

  file { "/etc/dovecot/dovecot-sql.conf.ext":
    ensure  => present,
    content => template($sqlconftemplate),
    mode    => '0600',
    owner   => root,
    group   => dovecot,
    require => Package['dovecot-mysql'],
    before  => Exec['dovecot'],
    notify  => Service['dovecot'],
  }

  package {'dovecot-mysql':
    ensure => installed,
    before => Exec['dovecot'],
    notify => Service['dovecot']
  }

  dovecot::config::dovecotcfmulti { 'sqlauth':
    config_file => 'conf.d/10-auth.conf',
    changes     => [
      "set include 'auth-sql.conf.ext'",
      "rm  include[ . = 'auth-system.conf.ext']",
    ],
    require     => File["/etc/dovecot/dovecot-sql.conf.ext"]
  }
}
