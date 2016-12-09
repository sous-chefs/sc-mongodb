# mongodb | mongod
describe service('mongodb') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

@test "replicaset initialized" {
    run mongo --eval "rs.status().ok"
    [ "$status" -eq 0 ]
    [ "${lines[@]:(-1)}" -eq 1 ]
}
