locals {
  haproxy-data = <<-EOF
#!/bin/bash
sudo -i
apt-get update -y
apt-get upgrade -y
apt install --no-install-recommends software-properties-common
add-apt-repository ppa:vbernat/haproxy-2.4 -y
apt install haproxy=2.4.\* -y 
haproxy -v
sudo bash -c 'cat << EOT > /etc/haproxy/haproxy.cfg
defaults
  log global
  maxconn 2000
  mode http
  option redispatch
  option http-server-close
  retries 3
  timeout http-request 10s
  timeout queue 1m
  timeout connect 10s
  timeout client 1m
  timeout server 1m
  timeout check 10s

frontend ft_jenkins
  bind *:80
  mode http
  option httplog
  default_backend bk_jenkins
  
  
backend bk_jenkins
  mode http
  option httplog
  balance roundrobin
  server jenkins1 ${aws_instance.jenkins-server-active.private_ip}:8080 check check inter 1000 rise 2 fall 3
  server jenkins2 ${aws_instance.jenkins-server-passive.private_ip}:8080 check backup inter 1000 rise 2 fall 3
EOT'
systemctl start haproxy
EOF  
}