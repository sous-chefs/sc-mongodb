require_relative '../../libraries/mongodb_config_helpers'

describe 'MongoDBConfigHelpers' do
  it 'convert to boost::program_options format' do
    extend ::MongoDBConfigHelpers
    input = {
      'string' => 'foo',
      'boolean' => true,
      'numeric' => 216,
      'absent' => nil
    }
    actual = to_boost_program_options input
    expected = <<EOF
boolean = true
numeric = 216
string = foo
EOF
    expect(actual).to eq(expected)
  end
end
