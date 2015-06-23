
server_ip = node['go']['agent']['server_host']
install_path = node['go']['agent']['install_path']

opts = ''
opts << "/SERVERIP=#{server_ip} " if node['go']['agent']['server_host']
opts << "/D=#{install_path}" if node['go']['agent']['install_path']

download_url = node['go']['agent']['download_url']
unless download_url
  download_url = 'http://download.go.cd/gocd/go-agent-' \
    "#{node['go']['version']}-setup.exe"
end

windows_package 'Go Agent' do
  source download_url
  options opts
  action :install
end

# Net and sc commands, as windows_service is not yet available for this chef 11

go_service_user = node['go']['agent_windows']['service_user']
go_service_password = node['go']['agent_windows']['service_password']

# Stop the service, synchronously
execute 'stop-go-service' do
  command "net stop \"Go Agent\""
  only_if { ::Win32::Service.status('Go Agent').current_state == 'running' && !go_service_user.nil? }
end

# Configure ntservice creds for service, sc is asynchronous
# which is why the stop/start use the "net" command instead

execute 'configure-service' do
  command "sc.exe config \"Go Agent\" " \
  "obj= \"#{go_service_user}\" password= \"#{go_service_password}\" type= own"
  not_if { go_service_user.nil? }
end

# Start the service, synchronously
execute 'start-go-service' do
  command "net start \"Go Agent\""
  only_if { ::Win32::Service.status('Go Agent').current_state != 'running' }
end
