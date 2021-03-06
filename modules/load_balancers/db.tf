/**
#################################################################################################################
*
*                               Load Balancer Section for the DB LB
*                                 Start Here of the DB LB Section 
*
#################################################################################################################
*/

/**
* Load Balancer For DB
**/
resource "ibm_is_lb" "db_lb" {
  name           = "${var.prefix}db-lb"
  resource_group = var.resource_group
  type           = "private"
  subnets        = var.db_subnet
}

/**
* Output Variable
* Element : Load Balancer
* LB ID For DB
* This variable will expose the LB ID for DB
**/
output "db_lb_id" {
  value       = ibm_is_lb.db_lb.id
  description = "DB load balancer ID"
}

/**
* Output Variable
* Element : Load Balancer IP
* LB IP For DB
* This variable will expose the LB IP for DB
**/
output "db_lb_ip" {
  value       = ibm_is_lb.db_lb.private_ips
  description = "Web load balancer IP"
}

/**
* Output Variable
* Element : Load Balancer Hostname
* LB Hostname For DB
* This variable output the Load Balancer's Hostname for DB
**/
output "db_lb_hostname" {
  value       = ibm_is_lb.db_lb.hostname
  description = "DB load balancer Hostname"
}

/**
* Load Balancer Listener For DB
**/
resource "ibm_is_lb_listener" "db_listener" {
  lb           = ibm_is_lb.db_lb.id
  protocol     = var.lb_protocol["80"]
  port         = "80"
  default_pool = ibm_is_lb_pool.db_pool.id
  depends_on   = [ibm_is_lb_pool.db_pool]
}

/**
* Load Balancer Pool For DB
**/
resource "ibm_is_lb_pool" "db_pool" {
  lb                 = ibm_is_lb.db_lb.id
  name               = "${var.prefix}db-pool"
  protocol           = var.lb_protocol["80"]
  algorithm          = var.lb_algo["rr"]
  health_delay       = "5"
  health_retries     = "2"
  health_timeout     = "2"
  health_type        = var.lb_protocol["80"]
  health_monitor_url = "/"
  depends_on         = [ibm_is_lb.db_lb]
}

/**
* Output Variable
* Element : LB Pool
* Pool ID For DB
* This variable will expose the Pool Id
**/
output "db_lb_pool_id" {
  value       = ibm_is_lb_pool.db_pool.id
  description = "DB load balancer pool ID"
}


/**
* Load Balancer Pool Member For DB
**/
resource "ibm_is_lb_pool_member" "db_lb_member" {
  count          = length(var.total_instance) * length(var.zones)
  lb             = ibm_is_lb.db_lb.id
  pool           = ibm_is_lb_pool.db_pool.id
  port           = var.lb_port_number["http"]
  target_address = element(var.db_target, count.index)
  depends_on     = [ibm_is_lb_listener.db_listener, var.db_vsi]
}

/**               
#################################################################################################################
*                              End of the DB Load Balancer Section 
#################################################################################################################
**/
