# Terraform

The Terraform file (main.tf) provisions load balanced, auto scaling EC2 instances accross a variety of availabilty zones. These present a simple frontend, displaying html contained within the shell script (apache_launch.sh). 

The terraform structure allows for the easy addition of further subnets in different AZs and differing amounts of instances. 
