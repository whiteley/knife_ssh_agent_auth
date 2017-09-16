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

file '/etc/opscode/users/aadmin.pem' do
  mode '0600'
end

bash 'generate-public-key' do
  code 'openssl rsa -in /etc/opscode/users/aadmin.pem -pubout | tee /etc/opscode/users/aadmin.pub'
end

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

execute 'ssh-add-key' do
  command 'ssh-add /etc/opscode/users/aadmin.pem'
  environment(
    SSH_AUTH_SOCK: '/tmp/aadmin.agent'
  )
end

execute 'ssh-list-key' do
  command 'ssh-add -l'
  environment(
    SSH_AUTH_SOCK: '/tmp/aadmin.agent'
  )
  notifies :delete, 'file[/etc/opscode/users/aadmin.pem]', :immediately
end

chef_gem 'net-ssh' do
  version '4.2.0'
end

git '/tmp/mixlib-authentication' do
  repository 'https://github.com/whiteley/mixlib-authentication.git'
  revision 'ssh-agent'
end

execute 'build-mixlib-authentication' do
  command 'rake install:local'
  cwd '/tmp/mixlib-authentication'
  environment(
    PATH: "/opt/chef/embedded/bin:#{ENV['PATH']}"
  )
end

execute 'knife-ssl-fetch' do
  command 'knife ssl fetch -c /etc/opscode/users/aadmin.rb'
end

execute 'knife-user-list' do
  command 'knife user list -c /etc/opscode/users/aadmin.rb'
  environment(
    SSH_AUTH_SOCK: '/tmp/aadmin.agent'
  )
end
