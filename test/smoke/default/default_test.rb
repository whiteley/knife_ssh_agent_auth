# # encoding: utf-8

# Inspec test for recipe knife_ssh_agent_auth::default

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

# the agent should have the private key loaded
describe bash('SSH_AUTH_SOCK=/tmp/aadmin.agent ssh-add -l') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match '/etc/opscode/users/aadmin.pem' }
  its('stderr') { should eq '' }
end

# the private key file should no longer exist
describe file('/etc/opscode/users/aadmin.pem') do
  it { should_not exist }
end

# knife operation should succeed with ssh-agent connection
describe bash('SSH_AUTH_SOCK=/tmp/aadmin.agent knife user list -c /etc/opscode/users/aadmin.rb') do
  its('exit_status') { should eq 0 }
  its('stdout') { should eq "aadmin\n" }
  its('stderr') { should eq '' }
end

# knife operation should fail without ssh-agent connection
describe bash('knife user list -c /etc/opscode/users/aadmin.rb') do
  its('exit_status') { should eq 100 }
  its('stdout') { should eq '' }
  its('stderr') { should eq "ERROR: Mixlib::Authentication::AuthenticationError: Could not connect to ssh-agent. Make sure the SSH_AUTH_SOCK environment variable is set properly! (Net::SSH::Authentication::AgentNotAvailable: Agent not configured)\n" }
end
