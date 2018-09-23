# one single dovecot config file change
define dovecot::config::dovecotcfsingle(
  $ensure = present,
  $config_file='dovecot.conf',
  $value=undef,
) {
  require dovecot::config::augeas
  Augeas {
    context => "/files/etc/dovecot/${config_file}",
    notify  => Service['dovecot'],
    require => Exec['dovecot'],
  }

  case $ensure {
    present: {
      if !$value {
        fail("dovecot /etc/dovecot/${config_file} ${name} value not set")
      }
      exec { "dovecot /etc/dovecot/${config_file} ${name} bodge" :
        command => "/bin/sed -i \"s@protocol !@protocolnoo @g\" /etc/dovecot/${config_file}"
      } ->
      augeas { "dovecot /etc/dovecot/${config_file} ${name}":
        changes => "set ${name} '${value}'",
      } ->
      exec { "dovecot /etc/dovecot/${config_file} ${name} unbodge" :
        command => "/bin/sed -i \"s@protocolnoo @protocol !@g\" /etc/dovecot/${config_file}"
      }
    }

    absent: {
      exec { "dovecot /etc/dovecot/${config_file} ${name} bodge" :
        command => "/bin/sed -i \"s@protocol !@protocolnoo @g\" /etc/dovecot/${config_file}"
      } ->
      augeas { "dovecot /etc/dovecot/${config_file} ${name}":
        changes => "rm ${name}",
      } ->
      exec { "dovecot /etc/dovecot/${config_file} ${name} unbodge" :
        command => "/bin/sed -i \"s@protocolnoo @protocol !@g\" /etc/dovecot/${config_file}"
      }
    }
    default : {
      notice('unknown ensure value use absent or present')
    }
  }
}
