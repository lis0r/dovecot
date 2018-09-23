# multiple dovecot config file changes at once
define dovecot::config::dovecotcfmulti(
  $config_file='dovecot.conf',
  $changes=undef,
  $onlyif=undef,
) {
  require dovecot::config::augeas
  Augeas {
    context => "/files/etc/dovecot/${config_file}",
    notify  => Service['dovecot'],
    require => Exec['dovecot'],
  }

  exec { "dovecot /etc/dovecot/${config_file} ${name} bodge" :
        command => "/bin/sed -i \"s@protocol !@protocol noo@g\" /etc/dovecot/${config_file}"
  } ->
  augeas { "dovecot /etc/dovecot/${config_file} ${name}":
    changes => $changes,
    onlyif  => $onlyif,
  } ->
  exec { "dovecot /etc/dovecot/${config_file} ${name} unbodge" :
        command => "/bin/sed -i \"s@protocol noo@protocol !@g\" /etc/dovecot/${config_file}"
  }
}
