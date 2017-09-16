# knife_ssh_agent_auth

A proof of concept for https://github.com/chef/mixlib-authentication/pull/27 showing knife operations happening via `ssh-agent` signing.

`kitchen test` will
* install and start the chef server
* create a user
* create an org with that user as admin
* create a knife configuration file suitable for testing
* start an ssh-agent and load the chef client key
* perform a knife operation using ssh-agent to sign

`kitchen converge` -> `kitchen login` can be used to run additional knife operations

```
kitchen$ sudo SSH_AUTH_SOCK=/tmp/aadmin.agent knife environment show _default -c /etc/opscode/users/aadmin.rb
```

This allows the chef admin to encrypt their private key, add it to `ssh-agent` with the passphrase and use `knife` as normal without leaving the unencrypted private key on disk. Normal `ssh-agent` features such as forwarding work without modification, so the chef admin may have their encrypted private key on a local workstation and perform operations using it from another machine such as a bastion with unfettered access to the chef server.
