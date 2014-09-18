#!/usr/bin/env ruby
#
# Sensu Handler: awsdecommission
#
# Copyright 2013, Bryan Brandau <agent462@gmail.com>
# Tweaked by Jerry Rose <github1@jerryrose.org>
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

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-handler'
require 'aws-sdk'

class AwsDecomm < Sensu::Handler

    def delete_sensu_client
      puts "Sensu client #{@event['client']['name']} is being deleted."
      retries = 1
      begin
        if api_request(:DELETE, '/clients/' + @event['client']['name']).code != '202' then raise "Sensu API call failed;" end
      rescue StandardError => e
        if (retries -= 1) >= 0
          sleep 3
          puts e.message + " Deletion failed; retrying to delete sensu client #{@event['client']['name']}."
          retry
        else
          puts @b << e.message + " Deleting sensu client #{@event['client']['name']} failed permanently."
          @s = "failed"
        end 
      end
    end

  def check_ec2
    instance = false
    %w{ ec2.eu-west-1.amazonaws.com }.each do |region|
      ec2 = AWS::EC2.new(
        :credential_provider => AWS::Core::CredentialProviders::EC2Provider.new,
        :ec2_endpoint => region
      )

      retries = 1
      begin
        i = ec2.instances[@event['client']['name']]
        if i.exists?
          puts "Instance #{@event['client']['name']} exists; Checking state"
          instance = true
          if i.status.to_s === "terminated" || i.status.to_s === "shutting_down" || i.status.to_s === "stopping" || i.status.to_s === "stopped"
            puts "Instance #{@event['client']['name']} is #{i.status}; I will proceed with decommission activities."
            delete_sensu_client
          else
            puts "Client #{@event['client']['name']} is #{i.status}"
            @s = "alert"
            bail
          end
        end
      rescue AWS::Errors::ClientError, AWS::Errors::ServerError => e
        if (retries -= 1) >= 0
          sleep 3
          puts e.message + " AWS lookup for #{@event['client']['name']} has failed; trying again."
          retry
        else
          @b << "AWS instance lookup failed permanently for #{@event['client']['name']}."
          @s = "failed"
          bail(@b)
        end 
      end
    end
    if instance == false
      @b << "AWS instance was not found #{@event['client']['name']}."
      delete_sensu_client
    end
  end
  
  def handle
    @b = ""
    @s = ""
    if @event['action'].eql?('create')
      check_ec2
      if @s === "" then @s = "success" end
    elsif @event['action'].eql?('resolve')
      @s = "resolve"
    end
  end

end
