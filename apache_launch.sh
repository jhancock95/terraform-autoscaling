#! /bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudp apt-get install libapache2-mod-wsgi-py3
sudo systemctl start apache2
sudo systemctl enable apache2
echo "<h1>This EC2 instance was launched via Terraform!/h1>" | sudo tee /var/www/html/index.html