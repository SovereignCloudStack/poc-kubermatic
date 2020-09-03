[api]
enabled = false

[servers.default]
protocol = "tcp"
bind = "0.0.0.0:6443"
balance = "roundrobin"
max_connections = 10000
client_idle_timeout = "10m"
backend_idle_timeout = "10m"
backend_connection_timeout = "2s"

[servers.default.discovery]
kind = "static"
static_list = [
    %{ for target in lb_targets ~}
    "${target}:6443",
    %{ endfor ~}
]

[servers.default.healthcheck]
kind = "ping"
interval = "10s"
timeout = "2s"
fails = 2
passes = 1

[servers.ingress80]
protocol = "tcp"
bind = "0.0.0.0:80"
balance = "roundrobin"
max_connections = 10000
client_idle_timeout = "10m"
backend_idle_timeout = "10m"
backend_connection_timeout = "2s"

[servers.ingress80.discovery]
kind = "static"
static_list = [
    %{ for target in lb_targets ~}
    "${target}:30080",
    %{ endfor ~}
]

[servers.ingress80.healthcheck]
kind = "ping"
interval = "10s"
timeout = "2s"
fails = 2
passes = 1

[servers.ingress443]
protocol = "tcp"
bind = "0.0.0.0:443"
balance = "roundrobin"
max_connections = 10000
client_idle_timeout = "10m"
backend_idle_timeout = "10m"
backend_connection_timeout = "2s"

[servers.ingress443.discovery]
kind = "static"
static_list = [
    %{ for target in lb_targets ~}
    "${target}:30443",
    %{ endfor ~}
]

[servers.ingress443.healthcheck]
kind = "ping"
interval = "10s"
timeout = "2s"
fails = 2
passes = 1

# kubermatics cluster m2j6bjspw4
#
[servers.m2j6bjspw4]
protocol = "tcp"
bind = "0.0.0.0:30744"
balance = "roundrobin"
max_connections = 10000
client_idle_timeout = "10m"
backend_idle_timeout = "10m"
backend_connection_timeout = "2s"

[servers.m2j6bjspw4.discovery]
kind = "static"
static_list = [
    %{ for target in lb_targets ~}
    "${target}:30744",
    %{ endfor ~}
]

[servers.m2j6bjspw4.healthcheck]
kind = "ping"
interval = "10s"
timeout = "2s"
fails = 2
passes = 1

