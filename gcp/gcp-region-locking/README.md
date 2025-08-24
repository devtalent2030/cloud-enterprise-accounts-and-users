# Cloud Security Cookbook – Hands-On with Terraform and GCP

This repository contains my hands-on implementations of security and cloud governance recipes inspired by the *Cloud-Native Security Cookbook*.  
I use **Terraform** and **Google Cloud Platform (GCP)** to build, secure, and enforce policies in real-world cloud environments.  

## What’s in this Repo
- **Infrastructure as Code (IaC)** with Terraform  
- **Organization & Project Structures** on GCP  
- **Region Locking** using Organization Policies  
- **Centralized IAM** for scalable identity management  
- Practical experiments to validate constraints (e.g., blocked vs. allowed resource creation)  

## 🛠️ Recipe Highlight – Region Locking on GCP
- **Problem**: Enforce data sovereignty by ensuring workloads only run in Australian and Singapore regions.  
- **Solution**: Applied an **organization policy** (`constraints/gcp.resourceLocations`) with Terraform to restrict allowed regions.  
- **Experiment**:  
  - Blocked creation of a `us-central1` storage bucket (violated policy ❌).  
  - Allowed creation of `australia-southeast1` and `asia-southeast1` buckets (compliant ).  
- **Skills Demonstrated**:  
  - Writing reusable Terraform modules with variables.  
  - Managing GCP organization policies via IaC.  
  - Testing policy enforcement both in **Console** and **CLI**.  

## Why This Matters
- Shows experience in **governance at scale** (org-level enforcement).  
- Demonstrates ability to translate **business requirements (data residency)** into **technical controls (Org Policies)**.  
- Illustrates the use of **Terraform for repeatable, auditable deployments**.  

## 📂 Structure
Each recipe has:
- **Terraform files** (`main.tf`, `variables.tf`, `provider.tf`, etc.)  
- **README.md** explaining the problem, solution, and outcome (both for revision and external reference).  

