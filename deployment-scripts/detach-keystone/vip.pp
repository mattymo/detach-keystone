notice('MODULAR: detach-keystone/vip.pp')

$internal_int             = hiera('internal_int')
$public_int               = hiera('public_int',  undef)
$primary_controller_nodes = hiera('primary_controller_nodes', false)
$network_scheme           = hiera('network_scheme', {})
$keystone_vip             = hiera('keystone_vip', undef)

#FIXME(bpiotrowski): This netmask data is the same as mgmt network
if (hiera('vip_management_cidr_netmask', false)) {
  $vip_management_cidr_netmask = hiera('vip_management_cidr_netmask')
} else {
  $vip_management_cidr_netmask = netmask_to_cidr($primary_controller_nodes[0]['internal_netmask'])
}

$keystone_vip_data  = {
  namespace      => 'haproxy',
  nic            => $internal_int,
  base_veth      => "${internal_int}-hapr",
  ns_veth        => 'hapr-m',
  ip             => $keystone_vip,
  cidr_netmask   => $vip_management_cidr_netmask,
  gateway        => 'none',
  gateway_metric => '0',
  bridge         => $network_scheme['roles']['management'],
  other_networks => $vip_mgmt_other_nets,
  with_ping      => false,
  ping_host_list => '',
}

cluster::virtual_ip { 'keystone' :
  vip => $keystone_vip_data,
}
