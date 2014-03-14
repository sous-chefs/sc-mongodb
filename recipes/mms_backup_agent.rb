arch = node[:kernel][:machine]
package = 'https://mms.mongodb.com/download/agent/backup/mongodb-mms-backup-agent'

if node.platform_family?('debian')
  arch = 'amd64' if arch == 'x86_64'
  package = "#{package}_#{node[:mongodb][:mms_agent][:backup][:version]}_#{arch}.deb"
  provider = Chef::Provider::Package::Dpkg
elsif node.platform_family?('rhel') then
  package = "#{package}-#{node[:mongodb][:mms_agent][:backup][:version]}.#{arch}.rpm"
  provider = Chef::Provider::Package::Rpm
else
  Chef::Log.warn('Unsupported platform family for MMS Backup Agent.')
  return
end

remote_file "#{Chef::Config[:file_cache_path]}/mongodb-mms-monitoring-agent" do
  source package
end

package 'mongodb-mms-backup-agent' do
  source "#{Chef::Config[:file_cache_path]}/mongodb-mms-monitoring-agent"
  provider provider
end

service 'mongodb-mms-backup-agent' do
  provider Chef::Provider::Service::Upstart if node['mongodb']['apt_repo'] == 'ubuntu-upstart'
  supports :restart => true
  action [:start, :enable]
end

ruby_block 'update backup-agent.config' do
  block do
    orig_s = ''
    open('/etc/mongodb-mms/backup-agent.config') do |f|
      orig_s = f.read
    end
    s = orig_s
    s = s.gsub(/^apiKey=.*$/, "apiKey=#{node[:mongodb][:mms_agent][:api_key]}")

    node[:mongodb][:mms_agent][:backup].each do |key, value|
      s = s.gsub(/^#{key}\s?=.*$/, "#{key}=#{value}") unless key == 'version'
    end

    if s != orig_s
      Chef::Log.debug 'Settings changed, overwriting and restarting service'
      open('/etc/mongodb-mms/backup-agent.config', 'w') do |f|
        f.puts s
      end

      notifies :restart, resources(:service => 'mongodb-mms-backup-agent'), :delayed
    end
  end
end
