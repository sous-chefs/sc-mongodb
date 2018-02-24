#
# Cookbook Name:: mongodb
# Recipe:: mongo_gem
#
# Copyright 2011, edelight GmbH
# Authors:
#       Markus Korn <markus.korn@edelight.de>
#
# Copyright 2016-2017, Grant Ridder
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# The build-essential cookbook was not running during the compile phase, install gcc explicitly for rhel so native
# extensions can be installed
gcc = package 'gcc' do
  action :nothing
  only_if { platform_family?('rhel') }
end
gcc.run_action(:install)

sasldev_pkg = if platform_family?('rhel', 'amazon')
                'cyrus-sasl-devel'
              else
                'libsasl2-dev'
              end

package sasldev_pkg do
  action :nothing
end.run_action(:install)

node['mongodb']['ruby_gems'].each do |gem, version|
  chef_gem gem do
    version version
    compile_time false
  end
end
