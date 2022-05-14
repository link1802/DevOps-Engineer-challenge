#! /bin/bash
 set -euo pipefail
 export DEBIAN_FRONTEND=noninteractive
 NAME=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/hostname")
 IP=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip")
 cat <<EOF > /var/www/html/index.nginx-debian.html
      <pre>
      Name: $NAME
      IP: $IP
      </pre>
      </body>
      </html>
      EOF