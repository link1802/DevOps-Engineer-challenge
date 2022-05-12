#! /bin/bash
echo "Installing nginx..."
apt -y update
apt -y install nginx
service nginx start
