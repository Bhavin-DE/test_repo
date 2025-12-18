
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

**Output tables **

Following tables have been created with this pipeline.

- heroic-footing-446621-d9.raw.fees
  
- heroic-footing-446621-d9.staging.fees_staging
  
- heroic-footing-446621-d9.transformed.fees_transformed
  
- heroic-footing-446621-d9.mart.fees_mart:
  * month_since_first_payment: For mart, we have created a field called month_since_first_payment where 0 represents 1st payment month, 1 represents if client paid in following (2nd)| month, 2 represents if client paid in 3rd month and onwards. If they don't miss a month to pay then they will have a gap in numbers for month_since_first_payment.
    
  * client_fee_amount_cumulative: rolling sum of client's fee payment over fee months
    
  * adviser_fee_amount_cumulative: rolling sum of adviser's associated with client's payments. If a client has 1 advisor for 4 months and different adviser for next 2 months, adviser 1 will get rolling sum of 4 months and adviser 2 will get rolling sum of 2 months. So LTV associated for a particular client for adviser 1 will be 4th month value, while for adviser 2 it will be 2nd month value.
    
  * mart table is unique at client_id and fee_date grain.   

**Analytical queries**

As part of the task I have created following 3 queries to answer business questions asked in the task under /analytics folder.

- client_quarterly_ltv.sql
  
- cohort_jan_feb_6months.sql
  
- adviser_performance_6months.sql
  
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
