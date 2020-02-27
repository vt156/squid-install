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
auth_param basic program /usr/lib/squid3/basic_ncsa_auth /etc/squid/passwords
auth_param basic realm proxy
acl authenticated proxy_auth REQUIRED

# Privacy
via off
forwarded_for off
request_header_access Via deny all
request_header_access Forwarded-For deny all
request_header_access X-Forwarded-For deny all

acl SSL_ports port 443
acl Safe_ports port 443
acl Safe_ports port 80
acl CONNECT method CONNECT
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow authenticated

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