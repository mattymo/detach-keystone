notice('MODULAR: detach-keystone/haproxy.pp')

$keystone_ipaddresses  = hiera('keystone_ipaddresses')
$keystone_names        = hiera('keystone_names')
$keystone_vip          = hiera('keystone_vip')

Haproxy::Service        { use_include => true }
Haproxy::Balancermember { use_include => true }

Package['socat'] -> Class['openstack::ha::keystone']

class { 'openstack::ha::keystone':
  server_names        => $keystone_names,
  ipaddresses         => $keystone_ipaddresses,
  public_virtual_ip   => $keystone_vip,
  internal_virtual_ip => $keystone_vip,
}
package { 'socat':
  ensure => 'present',
}

