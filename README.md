Dataforge Lakehouse Platform (AWS)
Overview

This project implements a production-style AWS Lakehouse platform using Terraform, designed to demonstrate data engineering and platform engineering skills.

The platform ingests raw event data into S3, catalogs it with AWS Glue, governs access using Lake Formation, transforms data using Glue Spark jobs, and enables analytics via Athena workgroups — all with infrastructure managed as code.

This repository focuses on:

Data governance and security

Least-privilege access at the data layer

Reusable platform design

Operational correctness over toy examples

Architecture
High-level flow
S3 (raw zone)
   ↓
Glue Crawler
   ↓
Glue Data Catalog (raw_prod)
   ↓
Glue Spark Job (append-only)
   ↓
S3 (curated zone)
   ↓
Glue Data Catalog (curated_prod)
   ↓
Athena Workgroup (analytics-prod)

Zones
Zone	Purpose
Raw	Immutable landing zone for ingested events
Curated	Cleaned, query-optimized analytics tables
Results	Athena query results
Core Components
1. Infrastructure as Code (Terraform)

All infrastructure is provisioned via Terraform using a modular layout:

s3_bucket – raw, curated, and Athena results buckets

kms – customer-managed KMS keys per zone

glue – databases, crawlers, jobs

athena – workgroups with enforced settings

lakeformation – database, table, and column permissions

iam – workload and analyst roles

Terraform is executed using a platform automation role, not a human admin user.

2. Data Governance (Lake Formation)

Lake Formation is the authoritative access control layer for all data access.

Key characteristics:

IAM access to S3 is not sufficient to read data

All access is mediated through Lake Formation permissions

Default IAMAllowedPrincipals access is revoked

Permissions are explicitly granted at:

database level

table level

column level

This enables:

Fine-grained access control

Separation between raw and curated zones

Auditable, declarative permissions

3. Security Model
Terraform execution role

Broad infrastructure permissions (platform role)

Guardrails applied:

Short STS session duration

Explicit denies for dangerous IAM escalation actions

Designed for maintainability, not perfect least privilege

Principle: Platform automation roles are guarded, workload roles are strict.

Workload roles

Glue job role: raw read + curated write + KMS permissions

Athena analyst role: curated read only

No direct S3 access without Lake Formation grants

4. Glue Crawlers

Glue crawlers are used only to bootstrap schemas in the raw zone.

Design choices:

Raw data schema is discovered automatically

Curated schemas are controlled by transformation jobs

Crawlers do not overwrite curated tables

This prevents schema drift in analytics-facing datasets.

5. Glue Spark Job (Raw → Curated)

The transformation job follows an append-only pattern.

Why append-only?

Avoids race conditions

Supports replay/backfills

Aligns with event-sourcing principles

Enables deterministic reprocessing

Key behaviors:

Reads from raw tables

Adds derived columns (e.g., event_date)

Writes partitioned data to curated S3 paths

Updates curated Glue tables

6. Athena Analytics

Athena is configured using a dedicated workgroup:

Enforced result location

Query isolation

Scoped IAM + Lake Formation access

Analyst access:

Can query curated tables

Cannot access raw tables

Cannot see restricted columns when column-level permissions are applied

Column-Level Security

The platform supports column-level Lake Formation permissions.

Example:

Analysts can query curated events

Sensitive fields (e.g. user_id) can be excluded

Enforced at query runtime by Lake Formation

This demonstrates enterprise-grade governance without relying on application logic.

Operational Lessons & Design Decisions
Why not perfect least privilege everywhere?

Terraform execution roles are platform roles

Over-tightening leads to fragility and high maintenance cost

Security is enforced where it matters most:

data access

workload execution

governance boundaries

This mirrors real-world platform engineering trade-offs.

What This Project Demonstrates

End-to-end lakehouse design

Terraform at scale (not toy examples)

Lake Formation mastery (including pitfalls)

IAM + KMS + S3 interaction under governance

Real debugging of AWS permission models

Senior-level decision making around security vs maintainability

Future Extensions

This platform is intentionally reusable and extensible. Possible next steps:

Streaming ingestion (Kinesis / MSK)

Data quality enforcement (Great Expectations / Deequ)

Cost governance (Athena query limits, budgets)

CI/CD for Terraform and Glue jobs

Iceberg table format adoption

Disclaimer

This project is deployed in a personal AWS account for learning and demonstration purposes.
Security controls are designed to reflect real-world best practices, not compliance checklists.