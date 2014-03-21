Chef::Log.warn 'Found empty mms_agent.api_key attribute' if node['mongodb']['mms_agent']['api_key'].nil?

arch = node[:kernel][:machine]
package = 'https://mms.mongodb.com/download/agent/monitoring/mongodb-mms-monitoring-agent'

case node.platform_family
when 'debian'
  arch = 'amd64' if arch == 'x86_64'
  package = "#{package}_#{node[:mongodb][:mms_agent][:monitoring][:version]}_#{arch}.deb"
  provider = Chef::Provider::Package::Dpkg
when 'rhel'
  package = "#{package}-#{node[:mongodb][:mms_agent][:monitoring][:version]}.#{arch}.rpm"
  provider = Chef::Provider::Package::Rpm
else
  Chef::Log.warn('Unsupported platform family for MMS Monitoring Agent.')
  return
end

remote_file "#{Chef::Config[:file_cache_path]}/mongodb-mms-monitoring-agent" do
  source package
end

package 'mongodb-mms-monitoring-agent' do
  source "#{Chef::Config[:file_cache_path]}/mongodb-mms-monitoring-agent"
  provider provider
end

service 'mongodb-mms-monitoring-agent' do
  provider Chef::Provider::Service::Upstart if node['mongodb']['apt_repo'] == 'ubuntu-upstart'
  # restart is broken on rhel (MMS-1597)
  supports :restart => true if node['mongodb']['apt_repo'] == 'ubuntu-upstart'
  action [:start, :enable]
end

ruby_block 'update monitoring-agent.config' do
  block do
    config = ''
    open('/etc/mongodb-mms/monitoring-agent.config') do |f|
      config = f.read
    end
    api_key = node[:mongodb][:mms_agent][:api_key]
    # replace mmsApiKey, optionally followed by a space, followed by an equal sign, and not followed by the api_key
    changed = !!config.gsub!(/^mmsApiKey\s?=(?!#{api_key})$/, "mmsApiKey=#{api_key}")

    node[:mongodb][:mms_agent][:monitoring].each do |key, value|
      # replace key, optionally followed by a space, followed by an equal sign, and not followed by the value
      (changed = !!config.gsub!(/^#{key}\s?=(?!#{value}).*$/, "#{key}=#{value}") || changed) unless key == 'version'
    end

    if changed
      Chef::Log.debug 'Settings changed, overwriting and restarting service'
      open('/etc/mongodb-mms/monitoring-agent.config', 'w') do |f|
        f.puts config
      end

      notifies :restart, resources(:service => 'mongodb-mms-monitoring-agent'), :delayed
    end
  end
end
