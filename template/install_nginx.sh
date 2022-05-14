#! /bin/bash
      apt-get update
      apt-get install -y nginx
      ufw allow 'Nginx HTTP'