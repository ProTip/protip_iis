#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Cookbook Name:: iis
# Resource:: site
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

actions :add, :delete, :start, :stop, :restart, :config

attribute :site_name, :kind_of => String, :name_attribute => true
attribute :site_id, :kind_of => Integer
attribute :port, :kind_of => Integer
attribute :path, :kind_of => String
attribute :protocol, :kind_of => Symbol, :default => :http, :equal_to => [:http, :https]
attribute :host_header, :kind_of => String, :default => nil
attribute :bindings, :kind_of => String, :default => nil
attribute :application_pool, :kind_of => String, :default => nil
attribute :options, :kind_of => String, :default => ''
attribute :properties, :kind_of => Hash, :default => {}

attr_accessor :exists, :running

def initialize(*args)
  super
  @action = :add
end
