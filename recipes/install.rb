if node['mongodb']['install_method'] == "10gen" or node.run_list.recipes.include?("mongodb::10gen_repo") then
    include_recipe "mongodb::10gen_repo"
end

# update defaults
file node['mongodb']['sysconfig_file'] do
    content "ENABLE_MONGODB=no"
    owner "root"
    mode 0644
    action :create_if_missing
end

# and we install our own init file
if node['mongodb']['apt_repo'] == "ubuntu-upstart" then
    template_file = File.join(node['mongodb']['init_dir'], "#{node['mongodb']['type']}.conf")
else
    template_file = File.join(node['mongodb']['init_dir'], "#{node['mongodb']['type']}")
end

template template_file do
    cookbook node['mongodb']['template_cookbook']
    source node['mongodb']['init_script_template']
    group node['mongodb']['root_group']
    owner "root"
    mode "0755"
    variables({
        :provides => node['mongodb']['type'],
    })
    action :create
end

packager_opts = ""
case node['platform_family']
when "debian"
    # this options lets us bypass complaint of pre-existing init file
    # necessary until upstream fixes ENABLE_MONGOD/DB flag
    packager_opts = '-o Dpkg::Options::="--force-confold"'
end

# install
package node[:mongodb][:package_name] do
    options packager_opts
    action :install
    version node[:mongodb][:package_version]
end
