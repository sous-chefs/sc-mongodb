# All the configuration files that can be dumped
# the attribute-based-configuration
# dump anything into default['mongodb']['config'][<setting>] = <value>
# these options are in the order of mongodb docs

default['mongodb']['config']['port'] = node['mongodb']['port'] or 27017
default['mongodb']['config']['bind_ip'] = node['mongodb']['bind_ip'] or "0.0.0.0"
default['mongodb']['config']['logpath'] = File.join(node['mongodb']['logpath'], "#{node['mongodb']['type']}.log")
default['mognodb']['config']['logappend'] = true
if node.platform_family?("rhel", "fedora") then
    default['mongodb']['config']['fork'] = true
else
    default['mongodb']['config']['fork'] = false
end
default['mongodb']['config']['dbpath'] = node['mongodb']['dbpath'] or "/var/lib/mongodb"
default['mongodb']['config']['nojournal'] = node['mongodb']['nojournal'] or false
default['mongodb']['config']['rest'] = node['mongodb']['enable_rest'] or false
default['mongodb']['config']['smallfiles'] = node['mongodb']['smallfiles'] or false
default['mongodb']['config']['oplogSize'] = node['mongodb']['oplog_size'] or nil

default['mongodb']['config']['replSet'] = node['mongodb']['replicaset_name'] or nil
if node['mongodb']['key_file'] then
    default['mongodb']['config']['keyFile'] = "/etc/mongodb.key"
end
