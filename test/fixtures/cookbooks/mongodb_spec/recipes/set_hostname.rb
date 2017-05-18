['192.168.10.10 mongo1', '192.168.10.20 mongo2', '192.168.10.30 mongo3', '192.168.10.99 mongos'].each do |host|
  execute "set_hostnames for #{host}" do
    command "echo #{host} >> /etc/hosts"
  end
end

if node['platform_family'] == 'rhel' && node['platform_version'].to_i == 7
  execute 'fix_network' do
    command 'service NetworkManager stop && service network restart'
  end
end
