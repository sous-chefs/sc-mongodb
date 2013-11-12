default['mongodb']['sysconfig']['DAEMON'] = "/usr/bin/$NAME"
default['mongodb']['sysconfig']['DAEMONUSER'] = node['mongodb']['user']
default['mongodb']['sysconfig']['DAEMON_OPTS'] = "--config #{node['mongodb']['configfile']}"
default['mongodb']['sysconfig']['CONFIGFILE'] = node['mongodb']['configfile']
# should mongodb start?
default['mongodb']['sysconfig']['ENABLE_MONGODB'] = "yes"
default['mongodb']['sysconfig']['ENABLE_MONGOD'] = node['mongodb']['sysconfig']['ENABLE_MONGODB']
default['mongodb']['sysconfig']['ENABLE_MONGO'] = node['mongodb']['sysconfig']['ENABLE_MONGODB']
