#
# Cookbook Name:: newrelic
# Recipe:: server-monitor
#
# Copyright 2012-2013, Escape Studios
#

case node['platform']
    when "debian", "ubuntu", "redhat", "centos", "fedora", "scientific", "amazon", "smartos"
        package node['newrelic']['service_name'] do
            action :install
        end

        service "#{node['newrelic']['service_name']}" do
            supports :status => true, :start => true, :stop => true, :restart => true
            action :nothing # we delay startup until after the configuration is done
        end

        #configure your New Relic license key
        template "#{node['newrelic']['config_path']}/nrsysmond.cfg" do
            source "nrsysmond.cfg.erb"
            owner "root"
            group node['newrelic']['config_file_group']
            mode "640"

            license_key = node['newrelic']['server_monitoring']['license']
            if !license_key['data_bag_name'].empty?
                data_bag_name = license_key['data_bag_name']
                data_bag_item = license_key['data_bag_item']
                data_bag_value = license_key['data_bag_value']
                data_bag_object = Chef::EncryptedDataBagItem.load(data_bag_name, data_bag_item)
                license_key = data_bag_object[data_bag_value]
            end

            variables(
                :license => license_key,
                :logfile => node['newrelic']['server_monitoring']['logfile'],
                :loglevel => node['newrelic']['server_monitoring']['loglevel'],
                :proxy => node['newrelic']['server_monitoring']['proxy'],
                :ssl => node['newrelic']['server_monitoring']['ssl'],
                :ssl_ca_path => node['newrelic']['server_monitoring']['ssl_ca_path'],
                :ssl_ca_bundle => node['newrelic']['server_monitoring']['ssl_ca_bundle'],
                :pidfile => node['newrelic']['server_monitoring']['pidfile'],
                :collector_host => node['newrelic']['server_monitoring']['collector_host'],
                :timeout => node['newrelic']['server_monitoring']['timeout']
            )
            notifies :restart, "service[#{node['newrelic']['service_name']}]"
        end

        service "#{node['newrelic']['service_name']}" do
            action [:enable, :start] #starts the service if it's not running and enables it to start at system boot time
        end

    when "windows"
        include_recipe "ms_dotnet4"
        
        if node['kernel']['machine'] == "x86_64"
                windows_package "New Relic Server Monitor" do
                source "http://download.newrelic.com/windows_server_monitor/release/NewRelicServerMonitor_x64_#{node['newrelic']['server_monitoring']['windows_version']}.msi"
                options "/L*v install.log /qn NR_LICENSE_KEY=#{node['newrelic']['server_monitoring']['license']}"
                action :install
                version node['newrelic']['server_monitoring']['windows_version']
                checksum node['newrelic']['server_monitoring']['windows64_checksum']
            end
        else
            windows_package "New Relic Server Monitor" do
                source "http://download.newrelic.com/windows_server_monitor/release/NewRelicServerMonitor_x86_#{node['newrelic']['server_monitoring']['windows_version']}.msi"
                options "/L*v install.log /qn NR_LICENSE_KEY=#{node['newrelic']['server_monitoring']['license']}"
                action :install
                version node['newrelic']['server_monitoring']['windows_version']
                checksum node['newrelic']['server_monitoring']['windows32_checksum']
            end
        end

        # on Windows service creation/startup is done by the installer.

end
