require 'chefspec'
require 'chefspec/berkshelf'
require 'fauxhai'

describe 'sc-mongodb::default' do
  let(:chef_run) do
    ChefSpec::Runner.new(
      platform: 'ubuntu',
      version: '12.04'
    )
  end

  it 'should include install recipe, and enable mongodb service' do
    chef_run.converge(described_recipe)
    expect(chef_run).to include_recipe('sc-mongodb::install')
    expect(chef_run).to enable_service('mongodb')
  end

  it 'package install mongodb-org via mongodb-org' do
    chef_run.node.set.mongodb.install_method = 'mongodb-org'
    chef_run.converge(described_recipe)
    expect(chef_run).to include_recipe('sc-mongodb::mongodb_org_repo')
    expect(chef_run).to include_recipe('sc-mongodb::install')
    expect(chef_run).to install_package('mongodb-org')
    expect(chef_run).to enable_service('mongodb')
  end
end
