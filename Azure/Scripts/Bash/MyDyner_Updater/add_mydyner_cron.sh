#!/bin/bash

line="*/5 * * * *  curl -X POST 'https://<app_name>.azurewebsites.net/api/<function_name>?code=<function_key>&name=<a_rec_name>&zone=<dns_zone>' -d ''";
user=$(whoami);
(crontab -u "$user" -l; echo "$line" ) | crontab -u "$user" -
