# 20-lmtp.conf
class dovecot::lmtp (
  $mail_plugins       = '$mail_plugins',
  $postmaster_address = "root@${::fqdn}",
  $lmtp_path          = '/var/spool/postfix/private/dovecot-lmtp',
  $listen_address     = false,
  $listen_port        = '24',
  ) {
  include dovecot
  include dovecot::master # Must be included so that dovecot::master::postfix_* resolve

  # See the [Dovecot wiki](http://wiki2.dovecot.org/HowTo/PostfixDovecotLMTP) for more information.
  # This setup is targeted toward use with Postfix via a unix socket.

  $package_name = $::osfamily ? {
    'Debian' => 'dovecot-lmtpd',
    'Redhat' => 'dovecot',
    default  => 'dovecot-lmtpd',
  }

  if $::osfamily != 'Redhat' {
    # redhat package is already installed elsewhere, avoid duplicate declaration
    package { $package_name:
      ensure => installed,
      alias  => 'dovecot-lmtpd',
      before => Exec['dovecot']
    }
  } 

  if $dovecot::base::protocols !~ /lmtp/ {
    fail('lmtp must be added to dovecot::base::protocols, see http://wiki2.dovecot.org/LMTP')
  }

  dovecot::config::dovecotcfmulti { '/etc/dovecot/conf.d/20-lmtp':
    config_file => 'conf.d/20-lmtp.conf',
    changes     => [
      "set protocol[ . = \"lmtp\"]/mail_plugins \"${mail_plugins}\"",
      "set protocol[ . = \"lmtp\"]/postmaster_address \"${postmaster_address}\"",
      ],
  }

  dovecot::config::dovecotcfmulti { '/etc/dovecot/conf.d/10-master.conf-lmtp0':
    config_file => 'conf.d/10-master.conf',
    onlyif      => "match service[ . = \"lmtp\"]/unix_listener[ . = \"${lmtp_path}\"] size == 0 ",
    changes     => [
      "ins unix_listener after service[ . = \"lmtp\"]/unix_listener[last()]",
      "set service[ . = \"lmtp\"]/unix_listener[last()] \"${lmtp_path}\"",
      "set service[ . = \"lmtp\"]/unix_listener[ . = \"${lmtp_path}\"]/mode \"${dovecot::master::postfix_mod}\"",
      "set service[ . = \"lmtp\"]/unix_listener[ . = \"${lmtp_path}\"]/user \"${dovecot::master::postfix_username}\"",
      "set service[ . = \"lmtp\"]/unix_listener[ . = \"${lmtp_path}\"]/group \"${dovecot::master::postfix_groupname}\"",
      ],
  }

  dovecot::config::dovecotcfmulti { '/etc/dovecot/conf.d/10-master.conf-lmtp1':
    config_file => 'conf.d/10-master.conf',
    onlyif      => "match service[ . = \"lmtp\"]/unix_listener[ . = \"${lmtp_path}\"] size == 1 ",
    changes     => [
      "set service[ . = \"lmtp\"]/unix_listener[ . = \"${lmtp_path}\"]/mode \"${dovecot::master::postfix_mod}\"",
      "set service[ . = \"lmtp\"]/unix_listener[ . = \"${lmtp_path}\"]/user \"${dovecot::master::postfix_username}\"",
      "set service[ . = \"lmtp\"]/unix_listener[ . = \"${lmtp_path}\"]/group \"${dovecot::master::postfix_groupname}\"",
      ],
    require     => Dovecot::Config::Dovecotcfmulti['/etc/dovecot/conf.d/10-master.conf-lmtp0'],
  }

  if $listen_address {
    dovecot::config::dovecotcfmulti { 'Add lmtp inet_listener1' :
      config_file => 'conf.d/10-master.conf',
      onlyif      => "match service[ . = \"lmtp\"]/inet_listener[ . = \"lmtp\"] size == 0 ",
      changes     => [
        "ins inet_listener after service[ . = \"lmtp\"]/unix_listener[last()]",
        "set service[ . = \"lmtp\"]/inet_listener[last()] \"lmtp\"",
        "set service[ . = \"lmtp\"]/inet_listener[ . = \"lmtp\"]/address \"${listen_address}\"",
        "set service[ . = \"lmtp\"]/inet_listener[ . = \"lmtp\"]/port \"${listen_port}\"",
        ],
    }

    dovecot::config::dovecotcfmulti { 'Add lmtp inet_listener2':
      config_file => 'conf.d/10-master.conf',
      onlyif      => "match service[ . = \"lmtp\"]/inet_listener[ . = \"lmtp\"] size == 1 ",
      changes     => [
        "set service[ . = \"lmtp\"]/inet_listener[ . = \"lmtp\"]/address \"${listen_address}\"",
        "set service[ . = \"lmtp\"]/inet_listener[ . = \"lmtp\"]/port \"${listen_port}\"",
        ],
      require     => Dovecot::Config::Dovecotcfmulti['Add lmtp inet_listener1'],
    }
  } else {
    dovecot::config::dovecotcfmulti { 'Remove lmtp inet_listener':
      config_file => 'conf.d/10-master.conf',
      onlyif      => "match service[ . = \"lmtp\"]/inet_listener[ . = \"lmtp\"] size == 1 ",
      changes     => [
        "rm service[ . = \"lmtp\"]/inet_listener[ . = \"lmtp\"]",
        ],
    }
  }
}
