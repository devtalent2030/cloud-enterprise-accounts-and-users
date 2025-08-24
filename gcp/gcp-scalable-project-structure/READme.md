# Scalable Project Structures on GCP

## Problem
You need a repeatable, scalable way to organize projects for new teams inside a GCP organization.

## Solution
- Use Terraform to define core folders (`Bootstrap`, `Common`, `Production`, `NonProd`, `Development`).
- Onboard teams by automatically creating 4 projects under the right folders:
  - `<team>Production`
  - `<team>PreProduction`
  - `<team>Development`
  - `<team>Shared`

## Discussion
- GCP has a 3-tier hierarchy: **Organization → Folder → Project**.
- Core folders keep infra structured and separate responsibilities.
- Production is tightly controlled, Dev allows experimentation, PreProd mimics Prod, Shared holds shared infra.
- You can migrate projects later (Import/Export folders are used temporarily).

## What You Deployed
- Organization with 5 core folders.
- A team-specific set of 4 projects under the folders.
- Terraform config (`provider.tf`, `variables.tf`, `main.tf`) that lets you re-create this structure anytime.
