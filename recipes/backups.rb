include_recipe "cpan::bootstrap"

packages = %w{libio-socket-ssl-perl libfile-slurp-perl libnet-amazon-ec2-perl libdatetime-perl}
packages.each do |p|
  package p do
    action :install
  end
end

generate_raid_backups {}

cpan_client 'Any::Moose' do
  action 'install'
  install_type 'cpan_module'
  user 'root'
  group 'root'
  force true
end

cpan_client 'Path::Class' do
  action 'install'
  install_type 'cpan_module'
  user 'root'
  group 'root'
  force true
end

cpan_client 'Module::Build' do
  action 'install'
  install_type 'cpan_module'
  user 'root'
  group 'root'
  force true
end

#cpan_client 'Path::Class' do
#  action 'install'
#  user 'root'
#  group 'root'
#end

cpan_client 'MongoDB' do
  action 'install'
  install_type 'cpan_module'
  user 'root'
  group 'root'
  force true
end

cpan_client 'MongoDB::Admin' do
  action 'install'
  install_type 'cpan_module'
  user 'root'
  group 'root'
end

cookbook_file "/usr/local/bin/ec2-consistent-snapshot" do
  source "ec2-consistent-snapshot"
  owner "root"
  group "root"
  mode "0755"
end


