cluster_name = "poc-k8c"

control_plane_flavor  = "2C-4GB-40GB"
worker_flavor         = "2C-4GB-40GB"
lb_flavor             = "2C-4GB-40GB"
image                 = "Ubuntu 18.04"
external_network_name = "external"
availability_zone     = "south-2"
ssh_public_key_file   = "../work/poc-k8c.pub"
