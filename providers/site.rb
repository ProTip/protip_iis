#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Cookbook Name:: iis
# Provider:: site
#
# Copyright:: 2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/mixin/shell_out'

include Chef::Mixin::ShellOut
include Windows::Helper

action :add do
  unless @current_resource.exists
    cmd = "#{appcmd} add site /name:\"#{@new_resource.site_name}\""
    cmd << " /id:#{@new_resource.site_id}" if @new_resource.site_id
    cmd << " /physicalPath:\"#{win_friendly_path(@new_resource.path)}\"" if @new_resource.path
  if @new_resource.bindings
    cmd << " /bindings:#{@new_resource.bindings}"
  else
    cmd << " /bindings:#{@new_resource.protocol}/*"
    cmd << ":#{@new_resource.port}:" if @new_resource.port
    cmd << "#{@new_resource.host_header}" if @new_resource.host_header
  end

    # support for additional options -logDir, -limits, -ftpServer, etc...
    if @new_resource.options
      cmd << " #{@new_resource.options}"
    end

    shell_out!(cmd, {:returns => [0,42]})

  if @new_resource.application_pool
    shell_out!("#{appcmd} set app \"#{@new_resource.site_name}/\" /applicationPool:\"#{@new_resource.application_pool}\"", {:returns => [0,42]})
  end
    @new_resource.updated_by_last_action(true)
    Chef::Log.info("#{@new_resource} added new site '#{@new_resource.site_name}'")
  else
    Chef::Log.debug("#{@new_resource} site already exists - nothing to do")
  end
end

action :config do

  if @new_resource.port
    cmd = "#{appcmd} set site \"#{@new_resource.site_name}\" "
    cmd << "/bindings:#{@new_resource.protocol.to_s}/*:#{@new_resource.port}:"
    cmd << properties_to_parameters(@new_resource.properties)
    Chef::Log.debug(cmd)
    shell_out!(cmd)
  else
    cmd = "#{appcmd} set site \"#{@new_resource.site_name}\" "
    cmd << " /bindings:#{@new_resource.bindings}" if @new_resource.bindings
    cmd << properties_to_parameters(@new_resource.properties)
    Chef::Log.debug(cmd)
    shell_out!(cmd)
  end


  if @new_resource.path
    cmd = "#{appcmd} set vdir \"#{@new_resource.site_name}/\" "
    cmd << "/physicalPath:\"#{@new_resource.path}\""
    Chef::Log.debug(cmd)
    shell_out!(cmd)
  end

  # pools looks like it's actually part of the app
  # if @new_resource.pool_name # it's actually set on the app
  #   cmd = "#{appcmd} set app \"#{@new_resource.site_name}\"/ "
  #   cmd << "/applicationPool:\"#{@new_resource.pool_name}\""
  #   Chef::Log.debug(cmd)
  #   shell_out!(cmd)
  # end

  if @new_resource.host_header
    # Need to figure out how to set host_header
    #cmd = "#{appcmd} set site \"#{@new_resource.site_name}\" "
    #cmd << "/applicationPool:\"#{@new_resource.pool_name}\""
    #Chef::Log.debug(cmd)
    #shell_out!(cmd)
  end

end

action :delete do
  if @current_resource.exists
    shell_out!("#{appcmd} delete site /site.name:\"#{site_identifier}\"", {:returns => [0,42]})
    @new_resource.updated_by_last_action(true)
    Chef::Log.info("#{@new_resource} deleted")
  else
    Chef::Log.debug("#{@new_resource} site does not exist - nothing to do")
  end
end

action :start do
  unless @current_resource.running
    shell_out!("#{appcmd} start site /site.name:\"#{site_identifier}\"", {:returns => [0,42]})
    @new_resource.updated_by_last_action(true)
    Chef::Log.info("#{@new_resource} started")
  else
    Chef::Log.debug("#{@new_resource} already running - nothing to do")
  end
end

action :stop do
  if @current_resource.running
    shell_out!("#{appcmd} stop site /site.name:\"#{site_identifier}\"", {:returns => [0,42]})
    @new_resource.updated_by_last_action(true)
    Chef::Log.info("#{@new_resource} stopped")
  else
    Chef::Log.debug("#{@new_resource} already stopped - nothing to do")
  end
end

action :restart do
  shell_out!("#{appcmd} stop site /site.name:\"#{site_identifier}\"", {:returns => [0,42]})
  sleep 2
  shell_out!("#{appcmd} start site /site.name:\"#{site_identifier}\"", {:returns => [0,42]})
  @new_resource.updated_by_last_action(true)
  Chef::Log.info("#{@new_resource} restarted")
end

def load_current_resource
  @current_resource = Chef::Resource::IisSite.new(@new_resource.name)
  @current_resource.site_name(@new_resource.site_name)
  cmd = shell_out("#{appcmd} list site")
  # 'SITE "Default Web Site" (id:1,bindings:http/*:80:,state:Started)'
  Chef::Log.debug("#{@new_resource} list site command output: #{cmd.stdout}")
  if cmd.stderr.empty?
    result = cmd.stdout.gsub(/\r\n?/, "\n") # ensure we have no carriage returns
    result = result.match(/^SITE\s\"(#{new_resource.site_name})\"\s\(id:(.*),bindings:(.*),state:(.*)\)$/)
  end
  Chef::Log.debug("#{@new_resource} current_resource match output: #{result}")
  if result
    @current_resource.site_id(result[2].to_i)
    @current_resource.exists = true
    bindings = result[3]
    @current_resource.running = (result[4] =~ /Started/) ? true : false
  else
    @current_resource.exists = false
    @current_resource.running = false
  end
end

private
def appcmd
  @appcmd ||= begin
    "#{node['iis']['home']}\\appcmd.exe"
  end
end

def site_identifier
  @new_resource.host_header || @new_resource.site_name
end

def properties_to_parameters( properties )
  parameters = ''
  properties.each { |property, value| parameters << " /#{property}:#{value}" }
  parameters
end