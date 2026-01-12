# Enterprise Multi-Tier Web App Deployment on AWS

## 🚀 Project Overview
This project demonstrates the deployment of an enterprise-grade Multi-Tier Web Application on AWS. Unlike simple single-server deployments, this architecture separates the application logic (Web Tier) from the data storage (Database Tier) to ensure scalability, security, and high availability.

The solution leverages a Custom Virtual Private Cloud (VPC) for network isolation, Amazon EC2 for web servers, Amazon RDS for managed database services, AWS Secrets Manager for secure credential management, and an Application Load Balancer (ALB) to distribute traffic efficiently.


## 🏗️ Architecture Design

![ARCHITECTURE](https://github.com/user-attachments/assets/c399eb38-1d74-4297-8234-b33abded414f)

The project addresses single points of failure and security risks found in monolithic applications by implementing a 3-Tier Architecture:

* **Public Subnet:** Hosts the Application Load Balancer (ALB) and NAT Gateway.
* **Private Subnet (Web Tier):** Hosts EC2 Instances running the WordPress application.
* **Private Subnet (Data Tier):** Hosts the Amazon RDS (MySQL) database.
* **Security Layer:** AWS Secrets Manager stores database credentials, removing the need for hardcoded passwords.

## 🛠️ AWS Services Used
* **Amazon VPC:** Custom network environment (10.0.0.0/16).
* **Amazon EC2:** Virtual servers for the web application.
* **Amazon RDS:** Managed MySQL database service.
* **AWS Secrets Manager:** Securely encrypts, stores, and rotates database credentials.
* **Application Load Balancer (ALB):** Distributes incoming traffic.
* **Auto Scaling Group (ASG):** Automatically adds or removes servers based on traffic.
* **NAT Gateway:** Allows private instances to download updates securely.

## 📋 Implementation Steps

### Step 1: Network Setup (VPC)
1.  **Create a VPC:** Named `My-Enterprise-VPC` with IPv4 CIDR `10.0.0.0/16`.
2.  **Subnets:** Created Public Subnets for the Load Balancer and Private Subnets for the Application and Database tiers across two Availability Zones (us-east-1a, us-east-1b) for redundancy.
3.  **Gateways:** Attached an Internet Gateway (IGW) for public access and a NAT Gateway to allow private instances to download software updates.
4.  **Routing:** Configured Route Tables to direct public traffic to the IGW and private traffic to the NAT Gateway.

<img width="1920" height="1280" alt="1 vpc" src="https://github.com/user-attachments/assets/6526b006-7746-4146-83c9-8af5909d1a09" />

### Step 2: Security Group Configuration (Chaining)
I implemented "Security Group Chaining" to enforce Least Privilege principles:

| Security Group Name | Inbound Rule | Source | Purpose |
| :--- | :--- | :--- | :--- |
| **ALB-SG** | HTTP (80) | 0.0.0.0/0 | Allows HTTP traffic from anywhere. |
| **Web-Tier-SG** | HTTP (80) | ALB-SG | Allows HTTP traffic *only* from the ALB. |
| **DB-SG** | MySQL (3306) | Web-Tier-SG | Allows MySQL traffic *only* from the Web Tier. |


<img width="1920" height="1280" alt="3 security groups" src="https://github.com/user-attachments/assets/359ef872-2acb-47b4-ac5e-214df5529e0f" />


### Step 3: Launch Web Tier (EC2 with Automation)
I launched an EC2 instance in the Private Subnet using a User Data Script to automatically provision the LAMP stack (Linux, Apache, MySQL, PHP) and WordPress.

**User Data Script:**
```bash
#!/bin/bash
dnf update -y
dnf install -y httpd wget php php-mysqli php-json php-common php-devel
systemctl start httpd
systemctl enable httpd
cd /var/www/html
wget [https://wordpress.org/latest.tar.gz](https://wordpress.org/latest.tar.gz)
tar -xzf latest.tar.gz
cp -r wordpress/*
rm -rf wordpress latest.tar.gz
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
echo "Healthy" > /var/www/html/health.html
```

<img width="1920" height="1280" alt="ec2instance" src="https://github.com/user-attachments/assets/aacb0f5a-d4c6-4674-a550-df7570c32ee2" />

### Step 4: Configure Application Load Balancer (ALB)
1.  Deployed an internet-facing ALB in the Public Subnets.
2.  **Target Group:** Registered the Web Tier EC2 instance as a target.
3.  **Health Check:** Configured the ALB to check `/health.html` (created in the script above) to ensure traffic is only sent to healthy instances.

<img width="1920" height="1280" alt="5 ALB" src="https://github.com/user-attachments/assets/19ac80ee-4f52-4486-8583-e7767d5d2f1e" />

<img width="1920" height="1280" alt="7  HEALTHY TARGETS" src="https://github.com/user-attachments/assets/8906d3ad-4f41-4ef3-9007-d7b09ae0ef5a" />

### Step 5: Deploy Database with Secrets Manager
1.  Provisioned a highly available Amazon RDS (MySQL) database in the Private Subnet.
2.  **Security:** Attached the Database SG to strictly limit access to the Web Tier.
3.  **Secrets Management:** Enabled "Manage master credentials in AWS Secrets Manager" to automatically generate and store a high-entropy password.

<img width="1920" height="1280" alt="8 RDS" src="https://github.com/user-attachments/assets/77d0af5f-861e-40e0-bfe0-ea186ad64368" />


<img width="1920" height="1280" alt="9 SECRETS MANAGER" src="https://github.com/user-attachments/assets/5d4f460e-0459-4761-b928-1b2129f3eb2b" />

### Step 6: WordPress Configuration & Credential Retrieval
1.  Navigated to **AWS Secrets Manager** to retrieve the secure database credentials.
2.  Accessed the application via the ALB DNS Link.
3.  Connected WordPress to the database using the RDS Endpoint and the credentials retrieved from Secrets Manager.

![BLOG11](https://github.com/user-attachments/assets/bfa119c9-aebf-449f-bc45-de39a2e633a1)

![BLOG22](https://github.com/user-attachments/assets/2c7de449-f7f6-419a-b55e-ea798cf294ce)

### Step 7: Auto Scaling & High Availability
To ensure resilience, I created an Auto Scaling Group (ASG):
1.  **Launch Template:** Created from the configured Web Instance (AMI).
2.  **Policy:** Configured to maintain a desired capacity of 2 instances, scaling up if CPU utilization exceeds 50%.
3.  **Testing:** Manually terminated an instance to verify that the ASG automatically detected the failure and launched a replacement.

<img width="1920" height="1280" alt="13 AUTOSCALING" src="https://github.com/user-attachments/assets/5bf20455-8e73-4e57-9746-b9c888fe2d43" />


<img width="1920" height="1280" alt="14 AUTOSCALING INSTANCES MANAGEMENT" src="https://github.com/user-attachments/assets/46cb4184-5d96-45bb-950f-49fccaa658ff" />

## 💡 Challenges & Solutions
* **⚠️ Challenge:** Managing Sensitive Database Credentials.
    * **Solution:** Integrated **AWS Secrets Manager** with RDS. This offloaded the responsibility of password complexity and storage to a managed service, ensuring compliance with security best practices.
* **⚠️ Challenge:** Load Balancer Availability Zones.
    * **Solution:** The ALB requires subnets in at least two Availability Zones (AZs). I created a secondary Public Subnet in `us-east-1b` to satisfy this requirement.

## ✅ Project Outcome
I successfully architected and deployed a fault-tolerant, scalable 3-Tier Web Application. The system automatically handles traffic spikes via Auto Scaling and self-heals in the event of server failure. By using AWS Secrets Manager, I demonstrated an enterprise-level approach to security.

---
*Created by [Oyeleke Ismail](https://www.linkedin.com/in/ismail-oyeleke-6930b6317/) - AWS Certified Solutions Architect*
