Disclaimer: This 3-tier stateless web terraform script is for experimental purposes with minimum support. Any open requests or issues will be addressed on a best effort basis.

# Overview

This is a self-service Infrastructure as Code (IAC) in the form of several terraform scripts.  The terraform scripts provide  an automated way for developers, DevOps, or system administrators to set up a resilient 3 tier stateless app on IBM Cloud Virtual Private Cloud (VPC).  The user can modify
the scripts and create templates to meet their application requirements.

Each tier contain the following VPC resources:
- IBM Cloud Load Balancer (lb)
  - web lb is public
  - app and db lb are private
- Virtual Server Instances (VSIs)
  - bastion public and floating IP
  - web, app, db VSIs private only
- Security groups

<img src="./images/terraform-digram-3-tier.svg" width=400>

## Pre-requisites
- VPC Account
- Linux box with Terraform v0.14.5 installed
- Knowledgeable with both IBM Cloud VPC and Terraform

NOTE: The variables are static and will need to be changed to your specifics.

## Usage

Step 1. Download the terraform scripts to your terraform server.

NOTE: The file structure must be maintained.

Step 2. Modify the variables in these files.  Some variables are optional with default
assigned values and other variables are required.

1. Main **variables.tf**
   - total_instance (optional)- Number of VSIs created per tier, per zone.  For example, if set to 2,
    then 2 VSIs are created in each tier for each zone (6 web VSIs, 6 app VSIs, and 6 db VSIs).
    Default to 1.
   - zones (optional) - Declares the availability zones within the region.  This should match the region that is
    defined in provider.tf region.  Defaults to the zones in Dallas.

2. **modules/subnets/subnet.tf**
   - [bastion, web, app, db] total_ipv4_address_count (optional) - Declares the number of useable IP
     addresses for each tier's subnet.  Value needs to be in binary number in decimal value. Defaults
     to 8.

3. **modules/security_groups/sg.tf**
   - Add additional security-groups (optional) - Copy the code snippet and paste it in 
     the respective tier.
```     
     resource "ibm_is_security_group_rule" "<<name>>" {
       group     = ibm_is_security_group.db.id
       direction = "[inbound|outbound]"
       remote    = "<<destination>>"
       tcp {
         port_min = "<<start_port_number>>"
         port_max = "<<end_port_number"
       }
     }
```
4. **modules/instances/variables.tf**
   - [bastion, web, app, db] image (required) - Image id of choice, it can be a custom import or one
     of the stock images.
   - [bastion, web, app, db] profile (required) - Declares the VSI profile for each VSI.
     Defaults to cx2-2x4, mx2-2x16, bx2-2x8 respectively.

5. **modules/load_balancers/variables.tf**
   - lb_port_number (optional) - If needed, add protocol and port number.  This will be referenced
     in the load_balancers [web, app, db] .tf files.

6. **modules/load_balancers/ [web, app, db].tf**
   - ibm_is_lb_listener (optional) - Declare which protocol to be listening on.  To add additional
     protocols copy and paste to the appropriate load_balancers .tf file.
     
     ```   
     resource "ibm_is_lb_listener" "app_listener" {
       lb           = ibm_is_lb.app_lb.id
       protocol     = var.lb_protocol["<<protocol from load balancers variable.tf"]
       port         = "<<port_number>>"
       default_pool = ibm_is_lb_pool.app_pool.id
       depends_on   = [ibm_is_lb_pool.app_pool]
       }
     ```

   - load balancer pool (optional) - Declares the backend protocol for the pool members. To add
     additional protocols, copy and paste the code snippet to the appropriate load balancer.
     
     ```
      resource "ibm_is_lb_pool" "app_pool" {
        lb                 = ibm_is_lb.app_lb.id
        name               = "${var.prefix}app-pool"
        protocol           = var.lb_protocol["<<protocol from load balancers variables.tf>>"]
        algorithm          = var.lb_algo["<<scheduling algorithm of choice from load balancer variables.tf>>"]
        health_delay       = "5"
        health_retries     = "2"
        health_timeout     = "2"
        health_type        = var.lb_protocol["<<protocol from load balancers variables.tf>>"]
        health_monitor_url = "/"
        depends_on         = [ibm_is_lb.app_lb]
      }
     ```

NOTE: When creating multiple listeners, there is a possibility where the load balancer status is stuck in updating. A rerun of the script will clear the issue.

**Some helpful terraform commands**
   - terraform init
   - terraform plan
   - terraform apply
   - terraform destroy
   - terraform state list

## Additional Resources
- https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs
- https://cloud.ibm.com/docs/terraform?topic=terraform-vpc-gen2-resources
- https://cloud.ibm.com/docs/terraform?topic=terraform-vpc-gen2-data-sources
