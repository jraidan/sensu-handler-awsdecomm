awsdecomm
=========

A sensu handler for decomission of AWS nodes in sensu. I tweaked the orginal to make use of an IAM role for EC2 API credentials and to remove the email and chef functions. 

Original:
http://www.ragedsyscoder.com/blog/2014/01/14/sensu-automated-decommission-of-clients/
https://github.com/agent462/sensu-handler-awsdecomm

Features
--------
* Checks state of node in AWS
* Decomission of node from Sensu
* Handles normal resolve/create keepalive events when decomm is not needed

Usage and Configuration
-----------------------
This handler uses the sensu-plugin. You installed using the Sensu "omnibus" packages, right?  :)

You will need to attach this to the default handler in sensu.  Sensu sends client keepalive failures to the default handler.  If a client keepalive gets sent to this handler it will proceed to check the instances status via the EC2 API and remove it from sensu if in a "terminated", "shutting_down", "stopping", or "stopped" state.

`/etc/sensu/conf.d/handlers_default.json`
````
{
  "handlers": {
    "default": {
      "type": "set",
      "handlers": [
        "awsdecommission"
      ]
    }
  }
}
````

`/etc/sensu/conf.d/handlers_awsdecommission.json`
````
{
  "handlers": {
    "awsdecommission": {
      "type": "pipe",
      "command": "/etc/sensu/handlers/awsdecomm.rb",
      "severities": [
        "ok",
        "warning",
        "critical"
      ]
    }
  }
}
````

awsdecomm relies on an IAM role with at least read-only permissions for the EC2 API.

Notables
--------
* The original author tried to incorporate mildly verbose logging to the sensu-server.log on each step. 
* This handler only checks the regions you specify on line 44 of the handler. Add more like so:

````
%w{ ec2.us-east-1.amazonaws.com ec2.us-west-2.amazonaws.com ec2.eu-west-1.amazonaws.com }.each do |region|
````

* This handler never terminates servers in AWS itself.  It simply takes action on nodes that do not exist or are in a terminated or shutting-down state.

Contributions
-------------
Please provide a pull request. 


License and Author
==================

Author:: Bryan Brandau <agent462@gmail.com>
Mangled by:: Jerry Rose <github1@jerryrose.org>

Copyright:: 2013, Bryan Brandau

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
