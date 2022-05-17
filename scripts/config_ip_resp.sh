#! /bin/bash
 set -euo pipefail
 export DEBIAN_FRONTEND=noninteractive
 IP=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip")
 cat > /var/www/html/index.nginx-debian.html 
 cat <<-EOF1 > /var/www/html/index.nginx-debian.html
      <html>
      <body>
      <pre>
      IP: $IP
      </pre>
      </body>
      </html>