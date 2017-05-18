# Overall testing

Please refer to
https://github.com/chef-cookbooks/community_cookbook_documentation/blob/master/TESTING.MD

# Replicaset testing

```bash
chef exec kitchen converge replicaset\\d-centos-73
chef exec kitchen verify replicaset3-centos-73
chef exec kitchen destroy replicaset\\d-centos-73
```
