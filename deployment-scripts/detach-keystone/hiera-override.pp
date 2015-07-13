notice('MODULAR: detach-keystone/hiera-override.pp')

$detach_keystone_plugin = hiera('detach-keystone')
$settings_hash          = parseyaml($detach_keystone_plugin['yaml_additional_config'])
$nodes_hash             = hiera('nodes')
$management_vip         = hiera('management_vip')
$keystone_vip           = pick(hiera('keystone_vip'), hiera('service_endpoint'))

if hiera('role', 'none') == 'primary-keystone' {
  $primary_keystone = 'true'
} else {
  $primary_keystone = 'false'
}
if hiera('role', 'none') =~ /^primary/ {
  $primary_controller = 'true'
} else {
  $primary_controller = 'false'
}

$keystone_nodes_ips   = nodes_with_roles($nodes_hash, ['primary-keystone',
  'keystone'], 'internal_address')
$keystone_nodes_names = nodes_with_roles($nodes_hash, ['primary-keystone',
  'keystone'], 'name')

case hiera('role', 'none') {
  /keystone/: {
    $corosync_roles = ['primary-keystone', 'keystone']
    $deploy_vrouter = 'false'
  }
  /controller/: {
    $deploy_vrouter = 'true'
    $mysql_enabled  = 'false'
  }
  default: {
    $corosync_roles = ['primary-controller', 'controller']
  }
}

$calculated_content = inline_template('
primary_keystone: <%= @primary_keystone %>
keystone_vip: <%= @keystone_vip %>
<% if @keystone_nodes_ips -%>
keystone_nodes:
<% @keystone_nodes_ips.each do |dbnode| %>  - <%= dbnode %><% end -%>
keystone_ipaddresses:
<% @keystone_nodes_ips.each do |dbnode| %>  - <%= dbnode %><% end -%>
<% end -%>
<% if @keystone_nodes_names -%>
keystone_names:
<% @keystone_nodes_names.each do |dbnode| %>  - <%= dbnode %><% end -%>
<% end -%>
primary_controller: <%= @primary_controller %>
<% if @corosync_roles -%>
corosync_roles:
<% @corosync_roles.each do |crole| %>  - <%= crole %><% end -%>
<% end -%>
deploy_vrouter: <%= @deploy_vrouter %>
')

file { '/etc/hiera/override':
  ensure  => directory,
}

file { '/etc/hiera/override/plugins.yaml':
  ensure  => file,
  content => "${detach_db_plugin['yaml_additional_config']}\n${calculated_content}\n",
  require => File['/etc/hiera/override']
}

package { 'ruby-deep-merge':
  ensure  => 'installed',
}

file_line { 'hiera.yaml':
  path => '/etc/hiera.yaml',
  line => ':merge_behavior: deeper',
}
