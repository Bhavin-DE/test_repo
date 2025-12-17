Lead Data Engineer – Take-Home Exercise

Overview

Fundment is a fast-growing wealth infrastructure company, building on our cutting-edge digital investment system to transform the £3 trillion UK wealth management market. We are passionate about revolutionising the investment experience for financial advisers and their clients by combining our innovative proprietary technology with exceptional customer service.

A key part of that is a data architecture where data correctness, trust, and transparency are foundational. Our data platform will support product decisions, financial reporting, and regulatory-adjacent workflows.

This exercise is designed to reflect the kind of work you would do as our Lead Data Engineer, building our data engineering function from the ground up.

We are not looking for a perfect or exhaustive solution. We are looking for sound engineering judgment, clear data modelling, and thoughtful communication.

⸻
Time Expectation
Please spend no more than 5 hours total on this exercise.

We explicitly value:
	•	Clear assumptions
	•	Good tradeoffs
	•	Simplicity over over-engineering

⸻
The Problem
You are given a dataset representing platform fees paid by clients over time.

Your task is to design and implement a simple, production-minded batch analytics pipeline on Google Cloud Platform (GCP) that:
	•	Ingests the raw data
	•	Stores it safely
	•	Transforms it into analytics-ready models
	•	Answers a small set of business questions using SQL

Assume this data will be used for:
	•	Business reporting
	•	Adviser performance analysis
	•	Financial oversight and trust-sensitive use cases

⸻
Dataset
The dataset is provided in the data/ directory as a CSV file.

Schema
client_id    STRING
client_nino	 STRING
adviser_id   STRING
fee_date     DATE
fee_amount   NUMERIC

Notes:
	•	A client may pay multiple fees per month
	•	A client may change advisers over time
	•	Data may contain duplicates or corrections
	•	Not all clients pay fees every month

You may make reasonable assumptions as needed, but please document them.

⸻
Technical Requirements
Infrastructure (Terraform + GCP)
Use Terraform to provision the minimum required infrastructure on GCP, that allows you to store and analyse data.

Guidelines:
	•	Keep Terraform minimal and readable
	•	Use variables where appropriate
	•	Assume this could later be extended to CI/CD
	•	You may use your own GCP account; please keep costs minimal

⸻
Data Pipeline
Design a simple batch pipeline that:
Uploads the raw CSV to GCP platform
Transforms it into one or more analytics-ready tables using SQL

Guidelines:
	•	Pipelines should be idempotent (safe to rerun)
	•	Clearly separate raw data from transformed data
	•	Prefer SQL-based transformations
	•	Focus on correctness and clarity

⸻
Business Questions to Answer
Using your data models, answer the following:

Client Lifetime Value (LTV)
What are the lifetime value (LTV), i.e. the accumulated fees, at 1, 3 and 6 months for each client, measured from the client’s first fee date?

⸻
Cohort LTV
What is the 6-month LTV for the January and February cohorts of the current year?
A cohort is defined by the month in which a client first paid a fee.

⸻
Adviser Performance
Which adviser has the highest total client LTV over the first 6 months of each client’s lifetime?

Please document how you attribute client LTV to advisers.

⸻
Deliverables
Please submit a GitHub repository (or zip file) containing:
README.md                # This file, updated with your notes
terraform/               # Terraform configuration
sql/                     # SQL models and/or queries
scripts/ (optional)      # Any helper scripts you use

⸻
README Expectations
Please update this README to include:
	•	A short description of your architecture
	•	Your data modelling approach
	•	Key assumptions and tradeoffs
	•	How you would evolve this into a production-grade, trustworthy fintech data platform
	•	Auditing and reconciliation
	•	Backfills and reprocessing
	•	Schema changes
	•	Data quality checks

Diagrams are welcome but not required.

⸻
What We’re Evaluating
We will evaluate submissions based on:
	•	Engineering judgment
	•	Data modelling fundamentals
	•	SQL correctness and readability
	•	Terraform clarity
	•	Trust and data-quality awareness
	•	Communication and documentation

We care more about how you think than how much you build.

⸻
What’s Out of Scope
You do not need to:
	•	Build dashboards or visualisations
	•	Implement streaming ingestion
	•	Set up CI/CD pipelines
	•	Optimise for very large scale
	•	Handle real customer data or PII

⸻
Follow-Up Discussion
In the follow-up interview, we will:
	•	Walk through your solution together
	•	Discuss tradeoffs and assumptions
	•	Explore how you would build and scale the data engineering function at Fundment
	•	Talk about operating data systems in a trust-sensitive fintech environment

⸻
Final Notes
This exercise is intended to be collaborative, not adversarial.

If something is ambiguous, make a reasonable assumption and document it.
If you choose not to implement something, explain why.

Thank you for your time and effort. We appreciate it!


**Description**

For this use case, I am using an architecture which is using Terraform (for infracture), GCP (BigQuery, Scheduled Queries, Data Transfer, GCS - for storage and processing) and SQL for data curation. As per requrement of this task, I have processed CSV through different stages and created a trasformed (fact) table (which holds the whole history of facts associated with client and advisor from csv along with some derived variables). This trasnformed table then feeds into mart table which which has additional fields required to support our business questions. End users can use this mart table to query/create views/aggregated tables at different grain for reporting and analysis.

**Assumptions**

- Source csv will be supplied on daily basis
- Duplicate records are considered as those records which have whole row same.
- Source file has fee_date as 1st of month for all records, so if client make multiple payments in a month, I assume they will resend all payments for that month where fee_date will be 1st of the month. If this assumption is not true then I can amend logic for transformed table accordingly.


**High Level Data Architecture and Pipeline**


**Terraform**

<img width="861" height="155" alt="Screenshot 2025-12-17 at 16 57 35" src="https://github.com/user-attachments/assets/b3cb4ea8-372d-4d9a-92d7-a392621cf069" />

**Google Cloud**

- We are using GCS bucket where csv will be dumped on daily basis. Once successfully processed it will be deleted (ideally it should be archived to archive process but I have added deletion due to time constraint)
  
- BigQuery where we are creating raw, staging, transformed and mart datasets.
  
- Data Transfer Service is being used to load csv into raw dataset
  
- Scheduled Queries is being used for processing data from raw > staging  > transformed > mart

**Data Transfer Service**

- We are using data trasnfer service to process csv from bucket into raw table. After successful processing, csv file gets deleted from bucket. If we want to re-process same file, then we will have to get that file again the bucket from source.

**SQL**

I am using sql scripts for data manipulation during each stage. SQL files are placed under /sql folder. This scripts should be used to create scheduled queries (scheduled queries can not directly use .sql file so we will have to copy paste it and create query but this helps in managing version of the script). 

- raw_to_staging.sql: This references to raw_to_staging.v2 scheduled query for processing data from raw to staging, removes duplicates, checks data is refreshed, add metadata fields.
  
- staging_to_transformed: This references to staging_to_transformed_v2 scheduled query for processing data from staging to transformed layer. It checks if staging is refreshed, remove duplicate rows, data cleaning, aggregation and deriving new fields. It holds the whole history at client_id and fee_date grain with upsert strategy.
  
- transformed_to_mart.sql: Thsi references to trasnformed_to_mart_v2 scheduled query for processing data from transformed to mart layer. It reads whole transformed table and create ltv fields which will be used for LTV analysis by end users. 

**Diagram**
This diagram shows our approach about how we are processing data from csv to target.

<img width="1468" height="557" alt="Screenshot 2025-12-17 at 16 55 58" src="https://github.com/user-attachments/assets/6a759011-3c12-4334-b791-70cb883ed575" />

**Data Quality and Monitoring**

I have covered following for data quality and monitoring perspective due to limition of time and tools  which have been used in the task:

- Data Quality: I have added filters for removing null, removed duplicates, created primary key for uniqueness.
  
- Monitorings: For monitoring, I have added email notification on failures, source fresheness as part of data transfer service and schedule queries

**How to develop a new pipeline**

- create (a new dataset - may not be required), a new table, a new bucket using terraform [terraform plan, terraform apply]
  
- After creating above assets, go to GCP console and manually create Data Trasfer Service to read csv into newly created raw table
  
- Create sql files for schedule queries locally for each layer (raw to staging, staging to transformed, transformed to mart)
  
- Push changes to Github
  
- After successful push, create schedule queries manually using sql files we pushed.


**Advantages of this design**

- Simple architecture which will serve use cases for this task and other use cases like ours in short timeframe with performance and cost efficiency
  
- basic checks and monitoring added without much complication which will help us in successful execution of pipeline
  
- clear separation between layers
  
- version control (we are creating schedule queries manually but making sure that we have related sql files as well to track changes)

**Disdvantages of this design**

- Scalability of data transfer service (as we are doing it manually). In ideal world, there would some sort of config which will pass on details to DTS on back of which trasnfers can be created to load data from csv to raw. Config can have parameters like schema, source file name, load type, partition etc.
  
- Scalability of scheduled queries and maintenance with code base (i.e. sql files)

- Scheduling without any orchestration tool without any control over it
  
- Missing Lineage [u sing BigQuery lineage is not same and will cost as well ], so one can deploy a change which will break pipeline
  
- Deletion of csv from bucket. Archive would be a better approach for replay.
  
- Missing self documentation (like DBT)
  
- Advance data qualities and observability
  
- Data Governance
  
- Separation of Environments
  
- Not proper data modelling as we only had one csv file. Ideally we can have dim_clients, dim_advisors, fact_fees

**Highlevel Enterprise Scale Data Architecture**

<img width="1357" height="515" alt="Screenshot 2025-12-17 at 21 41 56" src="https://github.com/user-attachments/assets/d4ed5351-e79c-45c8-b0e7-efda99d310ee" />
