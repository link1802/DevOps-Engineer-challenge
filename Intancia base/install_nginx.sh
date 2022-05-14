#! /bin/bash
 set -euo pipefail
 export DEBIAN_FRONTEND=noninteractive
 apt-get update -y
 apt-get install nginx -y
 rm /var/www/html/index.nginx-debian.html