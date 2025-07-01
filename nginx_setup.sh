#!/bin/bash

REQUIRED_TOOLS=("docker.io" "systemctl" "nano" "sudo" "nginx")

echo "Checking required tools..."
apt update && apt upgrade -y
for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    echo "$tool is NOT installed."
    echo "$tool is installing....."
    apt install "$tool" -y
  else
    :
  fi
done

# Create html_pages folder
HTML_DIR="html_pages"
mkdir -p "$HTML_DIR"

generate_unique_html_pages() {
  local count=${1:-5}

  local titles=("Dream Space" "Neon Vibes" "Tech Pulse" "Mystic Sky" "Color Rush")
  local descriptions=("Explore the future" "Feel the glow" "Powering innovation" "Enter the unknown" "Splash of imagination")
  local backgrounds=("#1e1e2f" "#000000" "#ffffff" "#003366" "#2c3e50")
  local textcolors=("#ffffff" "#00ffff" "#333333" "#ffcc00" "#ecf0f1")
  local layouts=(
'
<div class="box"><h1>%s</h1><p>%s</p></div>
'
'
<header><h1>%s</h1></header><section><p>%s</p></section>
'
'
<div class="card"><h1>%s</h1><p>%s</p></div>
'
'
<section class="hero"><h1>%s</h1><p>%s</p></section>
'
'
<div class="banner"><h1>%s</h1><p>%s</p></div>
'
)

  for i in $(seq 1 $count); do
    local title=${titles[$i % ${#titles[@]}]}
    local desc=${descriptions[$i % ${#descriptions[@]}]}
    local bg=${backgrounds[$i % ${#backgrounds[@]}]}
    local text=${textcolors[$i % ${#textcolors[@]}]}
    local layout=${layouts[$i % ${#layouts[@]}]}
    local filename="$HTML_DIR/unique_page_$i.html"

cat <<EOF > "$filename"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>$title</title>
  <style>
    body {
      background-color: $bg;
      color: $text;
      font-family: 'Segoe UI', sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      text-align: center;
    }
    .box, .card, .banner, .hero, section, header {
      padding: 40px;
      border-radius: 15px;
      box-shadow: 0 10px 20px rgba(0,0,0,0.2);
    }
    h1 {
      font-size: 3rem;
    }
    p {
      font-size: 1.2rem;
      margin-top: 1rem;
    }
  </style>
</head>
<body>
  $(printf "$layout" "$title" "$desc")
</body>
</html>
EOF

    echo "Created: $filename"
  done
}

read -p "Enter no of server to create....." no_of_server
server_port=()
server_html_file_path=()
server_count=0
for ((server=1; server<=no_of_server; server++)); do
  read -p "server $((server_count + 1)) port: " port
  read -p "server $((server_count + 1)) html page path or default it create.....: " path

  if [[ -z "$path" || ! -f "$path" ]]; then
    generate_unique_html_pages $((server_count + 1))
    path="$HTML_DIR/unique_page_$((server_count+1)).html"
  fi

  server_port+=("$port")
  server_html_file_path+=("$path")
  ((server_count++))
done

docker pull nginx:latest
systemctl enable nginx
systemctl start nginx
systemctl status nginx

create_containers() {
    local container_index="$1"
    local file_to_mount="$2"
    local container_port="$3"

    if [[ ! -f "$file_to_mount" ]]; then
        echo "Error: File '$file_to_mount' does not exist."
        return 1
    fi

    container_name="container_${container_index}"

    docker run -d \
        --name "$container_name" \
        -p "$container_port":80 \
        -v "$(realpath "$file_to_mount")":/usr/share/nginx/html/index.html \
        nginx

    echo "Started $container_name on port $container_port with $file_to_mount mounted."
}

server_count=0
for ((server=1; server<=no_of_server; server++)); do
  create_containers "$server_count" "${server_html_file_path[$server_count]}" "${server_port[$server_count]}"
  ((server_count++))
done

rm -f /etc/nginx/conf.d/default.conf
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/default.conf

nginx_conf_path="/etc/nginx/conf.d/nginx_config.conf"
echo "" > "$nginx_conf_path"

echo "upstream backend_servers {" >> "$nginx_conf_path"
for ((i=0; i<no_of_server; i++)); do
  port="${server_port[$i]}"
  echo "    server localhost:$port;" >> "$nginx_conf_path"
done
echo "}" >> "$nginx_conf_path"

cat >> "$nginx_conf_path" <<EOF
server {
    listen 80;
    server_name localhost;
    location / {
        proxy_pass http://backend_servers;
    }
}
EOF

systemctl reload nginx

apt install certbot python3-certbot-nginx -y
read -p "do you want to add domain or not (y/n): " input
if [[ $input == "y" ]]; then
    read -p "Enter domain name: " domain
    if [[ -z "$domain" ]]; then
      echo "No domain provided."
      exit 1
    fi
    nginx_conf=$(grep -Ril "$domain" /etc/nginx/sites-enabled /etc/nginx/conf.d 2>/dev/null)

    if [[ -n "$nginx_conf" ]]; then
      echo "Domain $domain is already configured in NGINX:"
      echo "$nginx_conf"
    else
      echo "Domain $domain is NOT configured in NGINX."
      sed -i "s/server_name localhost;/server_name localhost $domain;/" /etc/nginx/conf.d/nginx_config.conf
      systemctl stop nginx
      systemctl status nginx
      certbot --nginx
    fi
    nginx_conf_path="/etc/nginx/conf.d/nginx_config.conf"
    CERT_PATH="/etc/letsencrypt/live/$domain/fullchain.pem"

    if openssl s_client -connect "$domain:443" -servername "$domain" < /dev/null 2>/dev/null | openssl x509 -noout -checkend 0 > /dev/null; then
        echo "$domain is not running with ssl..."
    else
        if [ -f "$CERT_PATH" ]; then
            echo "SSL certificate exists for $domain"

            echo "" > "$nginx_conf_path"

            echo "upstream backend_servers {" >> "$nginx_conf_path"
            for ((i=0; i<no_of_server; i++)); do
                port="${server_port[$i]}"
                echo "    server localhost:$port;" >> "$nginx_conf_path"
            done
            echo "}" >> "$nginx_conf_path"

            cat >> "$nginx_conf_path" <<EOF

    server {
        listen 80;
        server_name $domain;
        return 301 https://\$host\$request_uri;
    }

    server {
        listen 443 ssl;
        server_name $domain;

        ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;

        location / {
            proxy_pass http://backend_servers;
        }
    }
EOF

            echo "Nginx config updated for $domain"
            systemctl restart nginx
        else
            echo "No certificate found for $domain"
            sudo certbot renew --post-hook "systemctl reload nginx"
        fi
    fi
else
  echo "Default localhost is setup...."
fi
