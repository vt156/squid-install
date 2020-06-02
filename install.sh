#!/bin/bash

# get username and password
USERNAME=${1:-"user1"}
PASSWORD=${2:-"foxfox1"}

# get packages
apt -y update
apt -y install squid
apt -y install expect
apt -y install apache2-utils

# replace squid config with this
echo "
# authentication scheme
auth_param basic program /usr/lib/squid3/basic_ncsa_auth /etc/squid/passwords
auth_param basic realm proxy

# Rules allowing access from your local networks.
# Adapt to list your (internal) IP networks from where browsing
# should be allowed
acl localnet src 192.168.0.0/24
acl authenticated proxy_auth REQUIRED
acl SSL_ports port 443
acl Safe_ports port 443
acl Safe_ports port 80
acl CONNECT method CONNECT

# Deny requests to certain unsafe ports
http_access deny !Safe_ports
# Deny CONNECT to other than secure SSL ports
http_access deny CONNECT !SSL_ports
# Allow access for authenticated users
http_access allow authenticated
# And finally deny all other access to this proxy
http_access deny all

# Privacy
via off
forwarded_for off
request_header_access Via deny all
request_header_access Forwarded-For deny all
request_header_access X-Forwarded-For deny all

# logfiles
access_log /var/log/squid/access.log
cache_log /var/log/squid/cache.log

http_port 3768
" > /etc/squid/squid.conf

# use expect to create user and set password for said user
echo "
spawn htpasswd -c /etc/squid/passwords $USERNAME
expect \"New password:\"
send \"$PASSWORD\r\"
expect \"Re-type new password:\"
send \"$PASSWORD\r\"
expect eof
exit
" > create_user.expect
/usr/bin/expect create_user.expect

# restart squid, check if it's working
service squid restart
systemctl status -n 0 squid