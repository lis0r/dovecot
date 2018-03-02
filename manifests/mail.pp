# 10-mail.conf
class dovecot::mail (
  $mailstoretype           = 'maildir',
  $mailstorepath           = '~/Maildir',
  $lock_method             = 'fcntl',
  $mbox_read_locks         = 'fcntl',
  $mbox_write_locks        = 'dotlock fcntl',
  $mail_nfs_storage        = 'no',
  $mail_nfs_index          = 'no',
  $mmap_disable            = 'yes',
  $mail_fsync              = 'always'
) {
  include dovecot

  if ( $mail_nfs_index == 'yes' and $mmap_disable != 'yes' ) {
    fail('mail_nfs_index=yes requires mmap_disable=yes')
  }

  if ( $mail_nfs_index == 'yes' and $mail_fsync != 'always' ) {
    fail('mail_nfs_index=yes requires mail_fsync=always')
  }

  dovecot::config::dovecotcfmulti { 'mail':
    config_file => 'conf.d/10-mail.conf',
    changes     => [
      "set mail_location '${mailstoretype}:${mailstorepath}'",
      "set lock_method '${lock_method}'",
      "set mbox_read_locks '${mbox_read_locks}'",
      "set mbox_write_locks '${mbox_write_locks}'",
      "set mail_nfs_storage '${mail_nfs_storage}'",
      "set mail_nfs_index '${mail_nfs_index}'",
      "set mmap_disable '${mmap_disable}'",
      "set mail_fsync '${mail_fsync}'",
    ],
  }
}
