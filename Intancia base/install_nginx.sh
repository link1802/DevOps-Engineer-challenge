#! /bin/bash
 set -euo pipefail
 export DEBIAN_FRONTEND=noninteractive
 apt-get update -y
 apt-get install ufw -y
 ufw allow 'Nginx HTTP'
 ufw allow 'SSH'
 ufw enable -y
 apt-get install nginx -y

 #NAME=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/hostname")
 #IP=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip")
 #cat <<EOF > /var/www/html/index.nginx-debian.html
 #     <pre>
 #     Name: $NAME
 #     IP: $IP
 #     </pre>
 #     </body>
 #     </html>
 #     EOF