#
# Cookbook:: knife_ssh_agent_auth
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

chef_ingredient 'chef-server' do
  action [:install, :reconfigure]
end

chef_user 'aadmin' do
  first_name 'alice'
  last_name 'admin'
  email 'aadmin@ponyville.local'
end

chef_org 'ponyville' do
  admins %w(aadmin)
end

# openssl public key generation fails with 0644
file '/etc/opscode/users/aadmin.pem' do
  mode '0600'
end

# public key is required for knife.rb
bash 'generate-public-key' do
  code 'openssl rsa -in /etc/opscode/users/aadmin.pem -pubout | tee /etc/opscode/users/aadmin.pub'
end

# template has required configuration to test ssh-agent signing
# client_key points to public key
# authentication_protocol_version set to 1.3
template '/etc/opscode/users/aadmin.rb' do
  source 'knife.rb.erb'
  variables(
    username: 'aadmin',
    orgname: 'ponyville',
    platform_public_url: "https://#{node[:fqdn]}"
  )
end

execute 'start-ssh-agent' do
  command 'ssh-agent -a /tmp/aadmin.agent'
end

# private key is deleted after loading in agent
execute 'ssh-add-key' do
  command 'ssh-add /etc/opscode/users/aadmin.pem'
  environment(
    SSH_AUTH_SOCK: '/tmp/aadmin.agent'
  )
  notifies :delete, 'file[/etc/opscode/users/aadmin.pem]', :immediately
end

# update required dependency
chef_gem 'net-ssh' do
  version '4.2.0'
end

# branch for https://github.com/chef/mixlib-authentication/pull/27
git '/tmp/mixlib-authentication' do
  repository 'https://github.com/whiteley/mixlib-authentication.git'
  revision 'ssh-agent'
end

# build and install patched mixlib-authentication
execute 'build-mixlib-authentication' do
  command 'rake install:local'
  cwd '/tmp/mixlib-authentication'
  environment(
    PATH: "/opt/chef/embedded/bin:#{ENV['PATH']}"
  )
end

# workaround for chef server self signed certificate
execute 'knife-ssl-fetch' do
  command 'knife ssl fetch -c /etc/opscode/users/aadmin.rb'
end
