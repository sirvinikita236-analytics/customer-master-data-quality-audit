# Customer Master Data Quality Audit & Validation

## 1. Project Overview

This project focuses on auditing and evaluating customer master data quality using SQL and MySQL Workbench.

The analysis uses a dataset containing 1,000 customer records to identify common data quality issues, including missing email addresses, invalid signup dates, invalid spend values, and duplicate customer IDs.

The project also applies data standardization techniques to improve consistency across customer country, segment, and active-status fields.

The objective is to assess the reliability of customer master data, quantify data quality exceptions, and provide actionable recommendations to support better data management and reporting.

## 2. Business Problem

Customer master data plays an important role in business operations. Inaccurate, incomplete, or inconsistent customer information can affect reporting, customer segmentation, analysis, and business decision-making.

The dataset used in this project contains several potential data quality issues, such as:

- Missing customer email addresses.
- Invalid or inconsistent signup dates.
- Missing, negative, or incorrectly formatted spend values.
- Duplicate customer IDs.
- Inconsistent country, customer segment, and active-status values.

The challenge is to identify, classify, and measure these issues using SQL while standardizing selected fields to improve data consistency.

This audit helps assess the extent of data quality exceptions and identify areas that require further investigation.

## 3. Dataset Description

The project uses a customer dataset containing **1,000 records and 8 original columns**.

The dataset includes the following fields:

| Column Name | Description |
|---|---|
| customer_id | Customer identifier |
| full_name | Customer's full name |
| email | Customer's email address |
| signup_date | Customer registration date |
| country | Customer's country |
| spend | Customer spending value |
| segment | Customer segment |
| is_active | Customer activity status |

The original dataset was retained as the source for analysis. Standardization and validation were performed separately to preserve the original data.

## 4. Tools & Technologies

- **MySQL:** Used for data profiling, standardization, querying, and data quality validation.
- **MySQL Workbench:** Used to write and execute SQL queries and review query results.
- **Microsoft Excel:** Used for initial dataset inspection and data profiling.
- **GitHub:** Used for project documentation and storing SQL scripts.

## 5. AI Assistance & Learning

ChatGPT was used as an AI-assisted learning and productivity tool during this project. It provided guidance on SQL concepts, query development, troubleshooting, understanding query results, and organizing project documentation.

The SQL queries were executed and their results reviewed in MySQL Workbench. The project is presented as a practical learning project, with a focus on understanding the data quality checks, validation logic, and findings.

## 6. Data Quality Assessment & Methodology

The data quality audit was performed using SQL queries in MySQL Workbench.

The process involved the following steps:

### 6.1 Data Profiling

- Inspected the source dataset and reviewed its structure.
- Checked record counts and column details.
- Identified missing values, inconsistent formats, and potential duplicate customer IDs.

### 6.2 Data Standardization

- Created a separate standardized table while preserving the original source data.
- Standardized country names, customer segment values, and active-status values.
- Applied consistent category mappings to handle variations in the source data.

### 6.3 Data Quality Validation

- Checked for missing or blank email addresses.
- Identified invalid and unrecognized signup date values.
- Validated spend values to identify missing, invalid, and negative amounts.
- Identified customer IDs appearing more than once.

### 6.4 Exception Analysis

- Created a SQL view to identify records containing one or more data quality exceptions.
- Used validation flags to classify the identified issues.
- Prepared a consolidated audit summary to measure the number and percentage of affected records.

## 7. Key Audit Results

The SQL-based audit identified the following data quality exceptions across 1,000 customer records.

### 7.1 Audit Summary

| Audit Metric | Records | Percentage |
|---|---:|---:|
| Total Source Records | 1,000 | 100.00% |
| Unique Exception Records | 215 | 21.50% |
| Missing Emails | 31 | 3.10% |
| Invalid Signup Dates | 54 | 5.40% |
| Spend Exceptions | 62 | 6.20% |
| Records with Repeated Customer IDs | 85 | 8.50% |

### 7.2 Key Observations

- **215 records (21.50%)** contained at least one identified data quality exception.
- **31 records (3.10%)** had missing email addresses.
- **54 records (5.40%)** contained invalid or unrecognized signup dates.
- **62 records (6.20%)** had missing, invalid, or negative spend values.
- **85 records (8.50%)** were associated with duplicate customer IDs.

### 7.3 Important Note

The exception categories may overlap because a single customer record can contain multiple data quality issues. Therefore, the individual exception counts should not be added together to calculate the total number of unique exception records.

The remaining **785 records (78.50%)** had no flagged exceptions under the validation checks performed. This does not necessarily mean that every field in those records is error-free.

## 8. Data Standardization Results

A separate standardized table was created to improve consistency in selected customer attributes while preserving the original source data.

The following standardization results were verified:

### 8.1 Country Standardization

| Standardized Country | Records |
|---|---:|
| United States | 294 |
| United Kingdom | 207 |
| Germany | 202 |
| Brazil | 154 |
| France | 143 |
| **Total** | **1,000** |

### 8.2 Customer Segment Standardization

| Standardized Segment | Records |
|---|---:|
| Enterprise | 283 |
| SMB | 281 |
| Mid-Market | 269 |
| Consumer | 167 |
| **Total** | **1,000** |

### 8.3 Active Status Standardization

| Standardized Status | Records |
|---|---:|
| No | 504 |
| Yes | 496 |
| **Total** | **1,000** |

These standardization steps helped bring variations in country names, customer segments, and active-status values into consistent categories.

## 9. Business Recommendations

Based on the audit findings, the following actions are recommended to improve customer master data quality:

1. **Missing Email Addresses:** Review records with missing email addresses and obtain the correct information from reliable sources where possible.

2. **Invalid Signup Dates:** Investigate invalid or unrecognized date values and verify them against the original customer records before correction.

3. **Invalid Spend Values:** Review missing, incorrectly formatted, and negative spend values. Negative amounts should be investigated because they may represent refunds or credits rather than errors.

4. **Duplicate Customer IDs:** Investigate repeated customer IDs to determine whether they represent duplicate records or legitimate records requiring further review.

5. **Consistent Data Standards:** Maintain standardized formats for country names, customer segments, and active-status values.

6. **Ongoing Data Quality Monitoring:** Introduce regular validation checks to identify missing, inconsistent, and duplicate data at an early stage.

These recommendations can help improve data reliability, reporting accuracy, and the overall management of customer information.

## 10. SQL Script Execution Notes

The SQL scripts are organized by project activity:

- **File 01:** Data profiling and exploratory analysis.
- **File 02:** Data standardization and related validation.
- **File 03:** Earlier validation queries retained for reference; not part of the final execution workflow.
- **File 04:** Creates the final customer data-quality exception view.
- **File 05:** Generates the final consolidated audit summary.

### Execution Guidelines

Files 01 and 02 contain exploratory queries and database-modification statements. They should not be executed as complete scripts against an already populated database without first checking the existing database objects.

Files 04 and 05 form the final audit reporting workflow. They require the source and standardized database tables to be available before execution.

Files 01–03 document the earlier development and validation process and should not be treated as a sequential execution script.
