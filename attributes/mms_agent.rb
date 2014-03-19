default[:mongodb][:mms_agent][:monitoring][:version] = '2.0.0.17-1'
default[:mongodb][:mms_agent][:backup][:version] = '1.4.3.28-1'

# deprecated attributes for mms_agent recipe

default[:mongodb][:mms_agent][:mms_server] = 'https://mms.mongodb.com'
# shouldn't need to changed, but configurable anyways
default[:mongodb][:mms_agent][:install_url] = 'https://mms.mongodb.com/settings/mms-monitoring-agent.zip'
# The mms-agent zip will be extracted into the install directory. Ultimately this means the install directory
# will have a sub directory named 'mms-agent' that comes from the zip.
default[:mongodb][:mms_agent][:install_dir] = '/usr/local/share/mms-agent'
default[:mongodb][:mms_agent][:log_dir] = File.join(File.dirname(node[:mongodb][:config][:logpath]), 'agent')
default[:mongodb][:mms_agent][:install_munin] = true
# this is the debian package name
default[:mongodb][:mms_agent][:munin_package] = 'munin-node'
default[:mongodb][:mms_agent][:enable_munin] = true

default[:mongodb][:mms_agent][:require_valid_server_cert] = false

default[:mongodb][:mms_agent][:user] = 'mmsagent'
default[:mongodb][:mms_agent][:group] = 'mmsagent'
