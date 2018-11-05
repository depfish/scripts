#!/usr/bin/env bash
# install dante-server_1.4.1(socks5 proxy) with radius(ldap) auth

apt-get -y install libpam-radius-auth libldap2-dev libpam-ldap

wget http://ppa.launchpad.net/dajhorn/dante/ubuntu/pool/main/d/dante/dante-server_1.4.1-1_amd64.deb && \
dpkg -i dante-server_1.4.1-1_amd64.deb

cp -p /etc/danted.conf /etc/danted.conf_bak_$(date +%Y-%m-%d-%s) 2>/dev/null
cat >/etc/danted.conf<<EOF
# /etc/danted.conf

logoutput: syslog
user.privileged: root
user.unprivileged: nobody

# The listening network interface or address.
internal: 0.0.0.0 port=10086

# The proxying network interface or address.
# 需要修改网卡接口，比如 eth0
external: eth0


# socks-rules determine what is proxied through the external interface.
# The default of "none" permits anonymous access.
##socksmethod: username
socksmethod: pam.username

# client-rules determine who can connect to the internal interface.
# The default of "none" permits anonymous access.
clientmethod: none

client pass {
        from: 0.0.0.0/0 to: 0.0.0.0/0
        log: connect disconnect error
}

socks pass {
        from: 0.0.0.0/0 to: 0.0.0.0/0
        protocol: tcp udp
        log: connect disconnect error
}



#forwarding route to SOCKS server (which supports both SOCKS version 4 and 5)
route {
        ##from: 0.0.0.0/0 to: 0.0.0.0/0 via: 192.168.149.4 port =  12346
        from: 0.0.0.0/0 to: 0.0.0.0/0 via: 10.28.10.83 port =  9137
        proxyprotocol: socks_v5
        command: connect
        protocol: tcp #udp not supported
        method: none
}
EOF

cp -p /etc/pam_radius_auth.conf /etc/pam_radius_auth.conf_bak_$(date +%Y-%m-%d-%s) 2>/dev/null
cat >/etc/pam_radius_auth.conf<<EOF
#  pam_radius_auth configuration file.  Copy to: /etc/raddb/server
#
#  For proper security, this file SHOULD have permissions 0600,
#  that is readable by root, and NO ONE else.  If anyone other than
#  root can read this file, then they can spoof responses from the server!
#
#  There are 3 fields per line in this file.  There may be multiple
#  lines.  Blank lines or lines beginning with '#' are treated as
#  comments, and are ignored.  The fields are:
#
#  server[:port] secret [timeout]
#
#  the port name or number is optional.  The default port name is
#  "radius", and is looked up from /etc/services The timeout field is
#  optional.  The default timeout is 3 seconds.
#
#  If multiple RADIUS server lines exist, they are tried in order.  The
#  first server to return success or failure causes the module to return
#  success or failure.  Only if a server fails to response is it skipped,
#  and the next server in turn is used.
#
#  The timeout field controls how many seconds the module waits before
#  deciding that the server has failed to respond.
#
# server[:port] shared_secret      timeout (s)
## 请添加场地 radius
54.223.xxx.xxx   PASSWORD             3
#other-server    other-secret       3

#
# having localhost in your radius configuration is a Good Thing.
#
# See the INSTALL file for pam.conf hints.
EOF



cat >/etc/pam.d/sockd<<EOF
auth    sufficient      pam_radius_auth.so
account sufficient      pam_radius_auth.so
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    optional     pam_keyinit.so force revoke
##session    include      system-auth
session    required     pam_limits.so
EOF

service danted  start
