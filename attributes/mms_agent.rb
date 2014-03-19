default[:mongodb][:mms_agent][:monitoring][:version] = '2.0.0.17-1'
default[:mongodb][:mms_agent][:backup][:version] = '1.4.3.28-1'

# deprecated attributes for mms_agent recipe

default[:mongodb][:mms_agent][:mms_server] = 'https://mms.mongodb.com'
# shouldn't need to changed, but configurable anyways
default[:mongodb][:mms_agent][:install_url] = 'https://mms.mongodb.com/settings/mms-monitoring-agent.zip'
# N.B. the dir MUST be named mms-agent; this is the contents of the unarchived zip
# the location of the dir (i.e. /usr/local/share) can be freely changed
default[:mongodb][:mms_agent][:install_dir] = '/usr/local/share/mms-agent'
default[:mongodb][:mms_agent][:log_dir] = File.join(File.dirname(node[:mongodb][:config][:logpath]), 'agent')
default[:mongodb][:mms_agent][:install_munin] = true
# this is the debian package name
default[:mongodb][:mms_agent][:munin_package] = 'munin-node'
default[:mongodb][:mms_agent][:enable_munin] = true

default[:mongodb][:mms_agent][:require_valid_server_cert] = false
