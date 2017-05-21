default['mongodb']['mms_agent']['api_key'] = nil
default['mongodb']['mms_agent']['mmsGroupId'] = nil

default['mongodb']['mms_agent']['user'] = 'mongodb-mms-agent'
default['mongodb']['mms_agent']['group'] = 'mongodb-mms-agent'

# See https://docs.cloud.mongodb.com/reference/automation-agent/ for more settings
default['mongodb']['mms_agent']['automation']['config']['mmsGroupId'] = nil
default['mongodb']['mms_agent']['automation']['config']['mmsApiKey'] = node['mongodb']['mms_agent']['api_key']
default['mongodb']['mms_agent']['automation']['config']['mmsBaseUrl'] = 'https://mms.mongodb.com'
default['mongodb']['mms_agent']['automation']['config']['logFile'] = '/var/log/mongodb-mms-automation/automation-agent.log'
default['mongodb']['mms_agent']['automation']['config']['mmsConfigBackup'] = '/var/lib/mongodb-mms-automation/mms-cluster-config-backup.json'
default['mongodb']['mms_agent']['automation']['config']['logLevel'] = 'INFO'
default['mongodb']['mms_agent']['automation']['config']['maxLogFiles'] = 10
default['mongodb']['mms_agent']['automation']['config']['maxLogFileSize'] = 268435456
case node['platform_family']
when 'rhel', 'fedora'
  default['mongodb']['mms_agent']['automation']['user'] = 'mongod'
  default['mongodb']['mms_agent']['automation']['group'] = 'mongod'
else
  default['mongodb']['mms_agent']['automation']['user'] = 'mongodb'
  default['mongodb']['mms_agent']['automation']['group'] = 'mongodb'
end

# See https://docs.cloud.mongodb.com/reference/backup-agent/ for more settings
default['mongodb']['mms_agent']['backup']['config']['mmsApiKey'] = node['mongodb']['mms_agent']['api_key']
default['mongodb']['mms_agent']['backup']['config']['mothership'] = 'api-backup.mongodb.com'
default['mongodb']['mms_agent']['backup']['config']['https'] = true
default['mongodb']['mms_agent']['backup']['user'] = node['mongodb']['mms_agent']['user']
default['mongodb']['mms_agent']['backup']['group'] = node['mongodb']['mms_agent']['user']

# See https://docs.cloud.mongodb.com/reference/monitoring-agent/ for more settings
default['mongodb']['mms_agent']['monitoring']['config']['mmsApiKey'] = node['mongodb']['mms_agent']['api_key']
default['mongodb']['mms_agent']['monitoring']['config']['mmsBaseUrl'] = 'https://mms.mongodb.com'
default['mongodb']['mms_agent']['monitoring']['user'] = node['mongodb']['mms_agent']['user']
default['mongodb']['mms_agent']['monitoring']['group'] = node['mongodb']['mms_agent']['user']

mms_agent_download_base = 'https://cloud.mongodb.com/download/agent'

case node['platform_family']
when 'amazon', 'fedora', 'rhel'
  extention = if node['platform_version'].to_i == 6
                'rpm'
              else
                'rhel7.rpm'
              end
  default['mongodb']['mms_agent']['automation']['package_url'] = "#{mms_agent_download_base}/automation/mongodb-mms-automation-agent-manager-latest.x86_64.#{extention}"
  default['mongodb']['mms_agent']['backup']['package_url'] = "#{mms_agent_download_base}/backup/mongodb-mms-backup-agent-latest.x86_64.rpm"
  default['mongodb']['mms_agent']['monitoring']['package_url'] = "#{mms_agent_download_base}/monitoring/mongodb-mms-monitoring-agent-latest.x86_64.rpm"
when 'debian'
  if node['platform'] == 'ubuntu' && node['platform_version'].to_f >= 15.04
    default['mongodb']['mms_agent']['automation']['package_url'] = "#{mms_agent_download_base}/automation/mongodb-mms-automation-agent-manager_latest_amd64.ubuntu1604.deb"
    default['mongodb']['mms_agent']['backup']['package_url'] = "#{mms_agent_download_base}/backup/mongodb-mms-backup-agent_latest_amd64.ubuntu1604.deb"
    default['mongodb']['mms_agent']['monitoring']['package_url'] = "#{mms_agent_download_base}/monitoring/mongodb-mms-monitoring-agent_latest_amd64.ubuntu1604.deb"
  else
    default['mongodb']['mms_agent']['automation']['package_url'] = "#{mms_agent_download_base}/automation/mongodb-mms-automation-agent-manager_latest_amd64.deb"
    default['mongodb']['mms_agent']['backup']['package_url'] = "#{mms_agent_download_base}/backup/mongodb-mms-backup-agent_latest_amd64.deb"
    default['mongodb']['mms_agent']['monitoring']['package_url'] = "#{mms_agent_download_base}/monitoring/mongodb-mms-monitoring-agent_latest_amd64.deb"
  end
end
