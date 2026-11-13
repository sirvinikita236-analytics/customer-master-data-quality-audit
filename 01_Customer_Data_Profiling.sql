USE customer_data_quality;

SELECT DATABASE() AS current_database;
SHOW TABLES;
SELECT 'customer_data_quality_raw' AS table_name, COUNT(*) AS total_records
FROM customer_data_quality_raw

UNION ALL

SELECT 'customer_data_quality_raw_clean', COUNT(*)
FROM customer_data_quality_raw_clean

UNION ALL

SELECT 'customer_data_quality_raw_final', COUNT(*)
FROM customer_data_quality_raw_final

UNION ALL

SELECT 'customer_data_quality_raw_v2', COUNT(*)
FROM customer_data_quality_raw_v2

UNION ALL

SELECT 'customer_data_quality_raw_verified', COUNT(*)
FROM customer_data_quality_raw_verified

UNION ALL

SELECT 'dirty-customers', COUNT(*)
FROM `dirty-customers`;
SELECT
    COUNT(*) AS distinct_full_rows,
    MIN(row_count) AS minimum_copies,
    MAX(row_count) AS maximum_copies,
    SUM(row_count - 2) AS copies_above_two
FROM (
    SELECT COUNT(*) AS row_count
    FROM customer_data_quality_raw_final
    GROUP BY
        customer_id,
        full_name,
        email,
        signup_date,
        country,
        spend,
        segment,
        is_active
) AS duplicate_check;
DESCRIBE customer_data_quality_raw_clean;
SELECT COUNT(*) AS total_records
FROM customer_data_quality_raw_clean;
SELECT
    customer_id,
    full_name,
    email,
    signup_date,
    country,
    spend,
    segment,
    is_active,
    COUNT(*) AS copies_found
FROM customer_data_quality_raw_final
GROUP BY
    customer_id,
    full_name,
    email,
    signup_date,
    country,
    spend,
    segment,
    is_active
HAVING COUNT(*) > 2;
CREATE TABLE customer_data_quality_source_reconstructed AS
SELECT
    customer_id,
    full_name,
    email,
    signup_date,
    country,
    spend,
    segment,
    is_active
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY
                customer_id,
                full_name,
                email,
                signup_date,
                country,
                spend,
                segment,
                is_active
            ORDER BY customer_id
        ) AS copy_rank
    FROM customer_data_quality_raw_final
) AS ranked_records
WHERE copy_rank <= 2;
CREATE TABLE customer_data_quality_source_1000 AS
SELECT
    customer_id,
    full_name,
    email,
    signup_date,
    country,
    spend,
    segment,
    is_active
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY
                customer_id, full_name, email, signup_date,
                country, spend, segment, is_active
            ORDER BY customer_id
        ) AS copy_rank,
        COUNT(*) OVER (
            PARTITION BY
                customer_id, full_name, email, signup_date,
                country, spend, segment, is_active
        ) AS copies
    FROM customer_data_quality_raw_final
) AS ranked_records
WHERE copy_rank = 1
   OR (copy_rank = 2 AND copies > 2);
   SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS distinct_customer_ids,
    SUM(CASE WHEN customer_id = 'CUST-1693' THEN 1 ELSE 0 END) AS expected_last_id_found
FROM customer_data_quality_source_1000;
SELECT
    customer_id,
    COUNT(*) AS occurrences
FROM customer_data_quality_source_1000
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC, customer_id;

USE customer_data_quality;

SELECT
    COUNT(*) AS total_records,

    SUM(customer_id IS NULL OR TRIM(customer_id) = '') AS missing_customer_id,
    SUM(full_name IS NULL OR TRIM(full_name) = '') AS missing_full_name,
    SUM(email IS NULL OR TRIM(email) = '') AS missing_email,
    SUM(signup_date IS NULL OR TRIM(signup_date) = '') AS missing_signup_date,
    SUM(country IS NULL OR TRIM(country) = '') AS missing_country,
    SUM(spend IS NULL OR TRIM(spend) = '') AS missing_spend,
    SUM(segment IS NULL OR TRIM(segment) = '') AS missing_segment,
    SUM(is_active IS NULL OR TRIM(is_active) = '') AS missing_active_status,

    SUM(LOWER(TRIM(signup_date)) IN
        ('null', 'none', 'n/a', '-', '-999')) AS placeholder_signup_date,

    SUM(LOWER(TRIM(spend)) IN
        ('null', 'none', 'n/a', '-', '-999')) AS placeholder_spend

FROM customer_data_quality_source_1000;
SELECT
    SUM(LOWER(TRIM(signup_date)) IN
        ('null', 'none', 'n/a', '-', '-999')) AS signup_date_placeholders,

    SUM(LOWER(TRIM(spend)) IN
        ('null', 'none', 'n/a', '-', '-999')) AS spend_placeholders

FROM customer_data_quality_source_1000;

USE customer_data_quality;

SELECT 'Missing customer ID' AS issue,
       COUNT(*) AS affected_records
FROM customer_data_quality_source_1000
WHERE customer_id IS NULL OR TRIM(customer_id) = ''

UNION ALL

SELECT 'Missing customer name',
       COUNT(*)
FROM customer_data_quality_source_1000
WHERE full_name IS NULL OR TRIM(full_name) = ''

UNION ALL

SELECT 'Missing email',
       COUNT(*)
FROM customer_data_quality_source_1000
WHERE email IS NULL OR TRIM(email) = ''

UNION ALL

SELECT 'Invalid email format',
       COUNT(*)
FROM customer_data_quality_source_1000
WHERE email IS NOT NULL
  AND TRIM(email) <> ''
  AND LOWER(TRIM(email)) NOT REGEXP
      '^[a-z0-9._%+-]+@[a-z0-9.-]+[.][a-z]{2,}$'

UNION ALL

SELECT 'Missing signup date',
       COUNT(*)
FROM customer_data_quality_source_1000
WHERE signup_date IS NULL OR TRIM(signup_date) = ''

UNION ALL

SELECT 'Signup date placeholders',
       COUNT(*)
FROM customer_data_quality_source_1000
WHERE LOWER(TRIM(signup_date))
      IN ('null', 'none', 'n/a', '-', '-999')

UNION ALL

SELECT 'Missing country',
       COUNT(*)
FROM customer_data_quality_source_1000
WHERE country IS NULL OR TRIM(country) = ''

UNION ALL

SELECT 'Missing spend',
       COUNT(*)
FROM customer_data_quality_source_1000
WHERE spend IS NULL OR TRIM(spend) = ''

UNION ALL

SELECT 'Spend placeholders',
       COUNT(*)
FROM customer_data_quality_source_1000
WHERE LOWER(TRIM(spend))
      IN ('null', 'none', 'n/a', '-', '-999')

UNION ALL

SELECT 'Missing customer segment',
       COUNT(*)
FROM customer_data_quality_source_1000
WHERE segment IS NULL OR TRIM(segment) = ''

UNION ALL

SELECT 'Missing active status',
       COUNT(*)
FROM customer_data_quality_source_1000
WHERE is_active IS NULL OR TRIM(is_active) = ''

UNION ALL

SELECT 'Records with repeated customer IDs',
       COUNT(*)
FROM customer_data_quality_source_1000 AS a
WHERE a.customer_id IS NOT NULL
  AND TRIM(a.customer_id) <> ''
  AND EXISTS (
      SELECT 1
      FROM customer_data_quality_source_1000 AS b
      WHERE b.customer_id = a.customer_id
      GROUP BY b.customer_id
      HAVING COUNT(*) > 1
  );
  
CREATE OR REPLACE VIEW customer_data_quality_exceptions AS

SELECT customer_id, 'Missing Email' AS issue_type,
       'email' AS field_name, email AS field_value
FROM customer_data_quality_source_1000
WHERE email IS NULL OR TRIM(email) = ''

UNION ALL

SELECT customer_id, 'Invalid Email Format',
       'email', email
FROM customer_data_quality_source_1000
WHERE email IS NOT NULL
  AND TRIM(email) <> ''
  AND LOWER(TRIM(email)) NOT REGEXP
      '^[a-z0-9._%+-]+@[a-z0-9.-]+[.][a-z]{2,}$'

UNION ALL

SELECT customer_id, 'Missing Signup Date',
       'signup_date', signup_date
FROM customer_data_quality_source_1000
WHERE signup_date IS NULL OR TRIM(signup_date) = ''

UNION ALL

SELECT customer_id, 'Signup Date Placeholder',
       'signup_date', signup_date
FROM customer_data_quality_source_1000
WHERE LOWER(TRIM(signup_date))
      IN ('null', 'none', 'n/a', '-', '-999')

UNION ALL

SELECT customer_id, 'Missing Spend',
       'spend', spend
FROM customer_data_quality_source_1000
WHERE spend IS NULL OR TRIM(spend) = ''

UNION ALL

SELECT customer_id, 'Spend Placeholder',
       'spend', spend
FROM customer_data_quality_source_1000
WHERE LOWER(TRIM(spend))
      IN ('null', 'none', 'n/a', '-', '-999')

UNION ALL

SELECT a.customer_id, 'Repeated Customer ID',
       'customer_id', a.customer_id
FROM customer_data_quality_source_1000 AS a
WHERE a.customer_id IS NOT NULL
  AND TRIM(a.customer_id) <> ''
  AND EXISTS (
      SELECT 1
      FROM customer_data_quality_source_1000 AS b
      WHERE b.customer_id = a.customer_id
      GROUP BY b.customer_id
      HAVING COUNT(*) > 1
  );
  SELECT *
FROM customer_data_quality_exceptions
ORDER BY issue_type, customer_id;
SELECT
    issue_type,
    COUNT(*) AS exception_count
FROM customer_data_quality_exceptions
GROUP BY issue_type
ORDER BY exception_count DESC;
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT customer_id) AS distinct_customer_ids,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_id_excess_rows,
    ROUND(
        (COUNT(*) - COUNT(DISTINCT customer_id)) * 100.0 / COUNT(*),
        2
    ) AS duplicate_id_excess_percentage
FROM customer_data_quality_source_1000;
SELECT
    COUNT(*) AS total_records,
    ROUND(100.0 * SUM(email IS NOT NULL AND TRIM(email) <> '') / COUNT(*), 2) AS email_completeness_pct,
    ROUND(100.0 * SUM(signup_date IS NOT NULL AND TRIM(signup_date) <> '') / COUNT(*), 2) AS signup_date_completeness_pct,
    ROUND(100.0 * SUM(spend IS NOT NULL AND TRIM(spend) <> '') / COUNT(*), 2) AS spend_completeness_pct
FROM customer_data_quality_source_1000;
SELECT
    COUNT(*) AS total_records,
    SUM(
        email IS NOT NULL
        AND TRIM(email) <> ''
        AND LOWER(TRIM(email)) REGEXP '^[a-z0-9._%+-]+@[a-z0-9.-]+[.][a-z]{2,}$'
    ) AS valid_email_records,
    SUM(
        email IS NOT NULL
        AND TRIM(email) <> ''
        AND NOT (
            LOWER(TRIM(email)) REGEXP '^[a-z0-9._%+-]+@[a-z0-9.-]+[.][a-z]{2,}$'
        )
    ) AS invalid_email_records
FROM customer_data_quality_source_1000;

SELECT
    'country' AS field_name,
    COALESCE(NULLIF(TRIM(country), ''), '[BLANK]') AS raw_value,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY COALESCE(NULLIF(TRIM(country), ''), '[BLANK]')

UNION ALL

SELECT
    'segment',
    COALESCE(NULLIF(TRIM(segment), ''), '[BLANK]'),
    COUNT(*)
FROM customer_data_quality_source_1000
GROUP BY COALESCE(NULLIF(TRIM(segment), ''), '[BLANK]')

UNION ALL

SELECT
    'is_active',
    COALESCE(NULLIF(TRIM(is_active), ''), '[BLANK]'),
    COUNT(*)
FROM customer_data_quality_source_1000
GROUP BY COALESCE(NULLIF(TRIM(is_active), ''), '[BLANK]')

ORDER BY field_name, raw_value;
SELECT
    TRIM(country) AS country_value,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY TRIM(country)
ORDER BY country_value;
SELECT
    TRIM(segment) AS segment_value,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY TRIM(segment)
ORDER BY segment_value;

USE customer_data_quality;

CREATE OR REPLACE VIEW customer_data_quality_standardized AS
SELECT
    customer_id,
    full_name,
    email,
    LOWER(TRIM(NULLIF(email, ''))) AS email_normalized,
    signup_date,
    country,

    CASE
        WHEN LOWER(TRIM(country)) IN ('germany', 'de')
            THEN 'Germany'
        WHEN LOWER(TRIM(country)) IN ('uk', 'gb', 'united kingdom')
            THEN 'United Kingdom'
        WHEN LOWER(TRIM(country)) IN ('u.s.', 'us', 'usa', 'united states')
            THEN 'United States'
        WHEN LOWER(TRIM(country)) IN ('brazil', 'br')
            THEN 'Brazil'
        WHEN LOWER(TRIM(country)) IN ('fr', 'france')
            THEN 'France'
        WHEN country IS NULL OR TRIM(country) = ''
            THEN NULL
        ELSE TRIM(country)
    END AS country_standardized,

    spend,
    segment,

    CASE
        WHEN LOWER(TRIM(segment)) IN ('enterprise', 'ent')
            THEN 'Enterprise'
        WHEN LOWER(TRIM(segment)) IN
            ('mid-market', 'mid market', 'midmarket')
            THEN 'Mid-Market'
        WHEN LOWER(TRIM(segment)) IN
            ('smb', 'small business')
            THEN 'SMB'
        WHEN LOWER(TRIM(segment)) = 'consumer'
            THEN 'Consumer'
        WHEN segment IS NULL OR TRIM(segment) = ''
            THEN NULL
        ELSE TRIM(segment)
    END AS segment_standardized,

    is_active,

    CASE
        WHEN LOWER(TRIM(is_active)) IN ('1', 'true', 'y', 'yes')
            THEN 1
        WHEN LOWER(TRIM(is_active)) IN ('0', 'false', 'n', 'no')
            THEN 0
        ELSE NULL
    END AS active_standardized

FROM customer_data_quality_source_1000;
SELECT
    customer_id,
    country,
    country_standardized,
    segment,
    segment_standardized,
    is_active,
    active_standardized
FROM customer_data_quality_standardized
LIMIT 20;
SELECT
    is_active,
    LOWER(TRIM(CAST(is_active AS CHAR))) AS normalized_value,
    CASE
        WHEN LOWER(TRIM(CAST(is_active AS CHAR)))
             IN ('1', 'true', 'y', 'yes') THEN 1
        WHEN LOWER(TRIM(CAST(is_active AS CHAR)))
             IN ('0', 'false', 'n', 'no') THEN 0
        ELSE NULL
    END AS active_test,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY is_active
ORDER BY is_active;
SELECT
    is_active,
    CASE LOWER(TRIM(CAST(is_active AS CHAR)))
        WHEN '1' THEN 1
        WHEN 'true' THEN 1
        WHEN 'y' THEN 1
        WHEN 'yes' THEN 1
        WHEN '0' THEN 0
        WHEN 'false' THEN 0
        WHEN 'n' THEN 0
        WHEN 'no' THEN 0
        ELSE NULL
    END AS active_test,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY is_active
ORDER BY is_active;
SELECT
    is_active,
    LOWER(TRIM(CAST(is_active AS CHAR))) AS normalized_value,
    CASE
        WHEN LOWER(TRIM(CAST(is_active AS CHAR))) IN ('1', 'true', 'y', 'yes') THEN 1
        WHEN LOWER(TRIM(CAST(is_active AS CHAR))) IN ('0', 'false', 'n', 'no') THEN 0
        ELSE NULL
    END AS active_test,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY is_active
ORDER BY is_active;
SELECT
    is_active,
    HEX(is_active) AS raw_hex,
    LENGTH(is_active) AS value_length,
    CASE
        WHEN LOWER(TRIM(is_active)) IN ('1', 'true', 'y', 'yes') THEN 1
        WHEN LOWER(TRIM(is_active)) IN ('0', 'false', 'n', 'no') THEN 0
        ELSE NULL
    END AS active_test
FROM customer_data_quality_source_1000
GROUP BY is_active;
SELECT
    is_active,
    LOWER(is_active) AS lower_value,
    LOWER(is_active) = 'false' AS test_false,
    LOWER(is_active) = 'true' AS test_true
FROM customer_data_quality_source_1000
GROUP BY is_active;
SELECT
    is_active,
    HEX(is_active) AS raw_hex,
    CASE HEX(is_active)
        WHEN '31' THEN 1
        WHEN '54525545' THEN 1
        WHEN '59' THEN 1
        WHEN '796573' THEN 1
        WHEN '30' THEN 0
        WHEN '46414C5345' THEN 0
        WHEN '4E' THEN 0
        WHEN '6E6F' THEN 0
        ELSE NULL
    END AS active_test,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY is_active;
SELECT
    is_active,
    REPLACE(TRIM(is_active), CHAR(13), '') AS cleaned_value,
    CASE
        WHEN LOWER(REPLACE(TRIM(is_active), CHAR(13), ''))
             IN ('1', 'true', 'y', 'yes') THEN 1
        WHEN LOWER(REPLACE(TRIM(is_active), CHAR(13), ''))
             IN ('0', 'false', 'n', 'no') THEN 0
        ELSE NULL
    END AS active_standardized,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY is_active;
SELECT
    CASE
        WHEN LOWER(REPLACE(TRIM(is_active), CHAR(13), ''))
             IN ('1', 'true', 'y', 'yes') THEN 'Active'
        WHEN LOWER(REPLACE(TRIM(is_active), CHAR(13), ''))
             IN ('0', 'false', 'n', 'no') THEN 'Inactive'
        ELSE 'Unmapped'
    END AS status_category,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY status_category;
CREATE OR REPLACE VIEW customer_data_quality_standardized AS
SELECT
    customer_id,
    full_name,
    email,
    signup_date,
    spend,
    country,
    CASE
        WHEN LOWER(TRIM(REPLACE(country, CHAR(13), '')))
             IN ('germany', 'de') THEN 'Germany'
        WHEN LOWER(TRIM(REPLACE(country, CHAR(13), '')))
             IN ('uk', 'united kingdom', 'gb') THEN 'United Kingdom'
        WHEN LOWER(TRIM(REPLACE(country, CHAR(13), '')))
             IN ('u.s.', 'united states', 'usa', 'us') THEN 'United States'
        WHEN LOWER(TRIM(REPLACE(country, CHAR(13), '')))
             IN ('brazil', 'br') THEN 'Brazil'
        WHEN LOWER(TRIM(REPLACE(country, CHAR(13), '')))
             IN ('fr', 'france') THEN 'France'
        ELSE TRIM(REPLACE(country, CHAR(13), ''))
    END AS country_standardized,
    segment,
    CASE
        WHEN LOWER(TRIM(segment)) IN ('enterprise', 'ent') THEN 'Enterprise'
        WHEN LOWER(TRIM(segment)) IN
             ('midmarket', 'mid market', 'mid-market') THEN 'Mid-Market'
        WHEN LOWER(TRIM(segment)) IN
             ('smb', 'small business') THEN 'SMB'
        WHEN LOWER(TRIM(segment)) = 'consumer' THEN 'Consumer'
        ELSE TRIM(segment)
    END AS segment_standardized,
    is_active,
    CASE
        WHEN LOWER(REPLACE(TRIM(is_active), CHAR(13), ''))
             IN ('1', 'true', 'y', 'yes') THEN 1
        WHEN LOWER(REPLACE(TRIM(is_active), CHAR(13), ''))
             IN ('0', 'false', 'n', 'no') THEN 0
        ELSE NULL
    END AS active_standardized
FROM customer_data_quality_source_1000;
SELECT
    customer_id,
    country,
    country_standardized,
    segment,
    segment_standardized,
    is_active,
    active_standardized
FROM customer_data_quality_standardized
LIMIT 20;
SELECT
    COUNT(*) AS total_records,
    SUM(country_standardized IS NULL) AS country_unmapped,
    SUM(segment_standardized IS NULL) AS segment_unmapped,
    SUM(active_standardized IS NULL) AS active_unmapped
FROM customer_data_quality_standardized;
SELECT
    COUNT(*) AS total_records,

    SUM(TRIM(COALESCE(email, '')) = '')
        AS missing_email,

    SUM(LOWER(TRIM(COALESCE(signup_date, '')))
        IN ('', 'null', 'none', 'n/a', '-', '-999'))
        AS invalid_signup_date,

    SUM(LOWER(TRIM(COALESCE(spend, '')))
        IN ('', 'null', 'none', 'n/a', '-', '-999'))
        AS invalid_spend,

    (
        SELECT COUNT(*)
        FROM (
            SELECT customer_id
            FROM customer_data_quality_source_1000
            GROUP BY customer_id
            HAVING COUNT(*) > 1
        ) AS duplicates
    ) AS duplicate_id_groups

FROM customer_data_quality_source_1000;
CREATE OR REPLACE VIEW customer_data_quality_exceptions AS
SELECT
    customer_id,
    full_name,
    email,
    signup_date,
    country,
    spend,
    segment,
    is_active,

    CASE
        WHEN TRIM(COALESCE(email, '')) = ''
        THEN 1 ELSE 0
    END AS missing_email_flag,

    CASE
        WHEN LOWER(TRIM(COALESCE(signup_date, '')))
        IN ('', 'null', 'none', 'n/a', '-', '-999')
        THEN 1 ELSE 0
    END AS invalid_signup_date_flag,

    CASE
        WHEN LOWER(TRIM(COALESCE(spend, '')))
        IN ('', 'null', 'none', 'n/a', '-', '-999')
        THEN 1 ELSE 0
    END AS invalid_spend_flag,

    CASE
        WHEN customer_id IN (
            SELECT customer_id
            FROM customer_data_quality_source_1000
            GROUP BY customer_id
            HAVING COUNT(*) > 1
        )
        THEN 1 ELSE 0
    END AS duplicate_id_flag

FROM customer_data_quality_source_1000

WHERE
    TRIM(COALESCE(email, '')) = ''
    OR LOWER(TRIM(COALESCE(signup_date, '')))
       IN ('', 'null', 'none', 'n/a', '-', '-999')
    OR LOWER(TRIM(COALESCE(spend, '')))
       IN ('', 'null', 'none', 'n/a', '-', '-999')
    OR customer_id IN (
        SELECT customer_id
        FROM customer_data_quality_source_1000
        GROUP BY customer_id
        HAVING COUNT(*) > 1
    );
    SELECT *
FROM customer_data_quality_exceptions
LIMIT 20;

USE customer_data_quality;

CREATE OR REPLACE VIEW customer_data_quality_exceptions AS

WITH cleaned AS (
    SELECT
        *,
        LOWER(TRIM(COALESCE(signup_date, ''))) AS date_norm,

        TRIM(
            REPLACE(
                REPLACE(
                    REPLACE(UPPER(TRIM(COALESCE(spend, ''))),
                    'USD', ''),
                '$', ''),
            ',', '')
        ) AS spend_norm

    FROM customer_data_quality_source_1000
),

parsed AS (
    SELECT
        *,

        CASE
            WHEN date_norm IN ('', 'null', 'none', 'n/a', '-', '-999')
                THEN NULL

            WHEN date_norm REGEXP '^[0-9]+([.]0+)?$'
                 AND CAST(date_norm AS UNSIGNED) BETWEEN 1 AND 80000
                THEN DATE_ADD(
                    '1899-12-30',
                    INTERVAL CAST(date_norm AS UNSIGNED) DAY
                )

            ELSE COALESCE(
                STR_TO_DATE(signup_date, '%b %e, %Y'),
                STR_TO_DATE(signup_date, '%m.%d.%Y'),
                STR_TO_DATE(signup_date, '%m/%d/%Y'),
                STR_TO_DATE(signup_date, '%d-%b-%y'),
                STR_TO_DATE(signup_date, '%d-%m-%Y'),
                STR_TO_DATE(signup_date, '%d/%m/%Y'),
                STR_TO_DATE(signup_date, '%Y-%m-%d')
            )
        END AS parsed_signup_date,

        CASE
            WHEN spend_norm REGEXP '^[0-9]+([.][0-9]+)?$'
                THEN CAST(spend_norm AS DECIMAL(12,2))
            ELSE NULL
        END AS spend_numeric

    FROM cleaned
)

SELECT
    customer_id,
    full_name,
    email,
    signup_date,
    parsed_signup_date,
    country,
    spend,
    spend_numeric,
    segment,
    is_active,

    CASE
        WHEN TRIM(COALESCE(email, '')) = ''
        THEN 1 ELSE 0
    END AS missing_email_flag,

    CASE
        WHEN parsed_signup_date IS NULL
        THEN 1 ELSE 0
    END AS invalid_signup_date_flag,

    CASE
        WHEN spend_numeric IS NULL OR spend_numeric < 0
        THEN 1 ELSE 0
    END AS invalid_spend_flag,

    CASE
        WHEN customer_id IN (
            SELECT customer_id
            FROM customer_data_quality_source_1000
            GROUP BY customer_id
            HAVING COUNT(*) > 1
        )
        THEN 1 ELSE 0
    END AS duplicate_id_flag

FROM parsed

WHERE
    TRIM(COALESCE(email, '')) = ''
    OR parsed_signup_date IS NULL
    OR spend_numeric IS NULL
    OR spend_numeric < 0
    OR customer_id IN (
        SELECT customer_id
        FROM customer_data_quality_source_1000
        GROUP BY customer_id
        HAVING COUNT(*) > 1
    );
    SELECT *
FROM customer_data_quality_exceptions
LIMIT 20;
SELECT COUNT(*) AS total_exception_records
FROM customer_data_quality_exceptions;
SELECT
    COUNT(*) AS total_records,
    SUM(TRIM(COALESCE(email, '')) = '') AS missing_email,
    SUM(parsed_signup_date IS NULL) AS invalid_signup_dates,
    SUM(spend_numeric IS NULL OR spend_numeric < 0) AS invalid_spend,
    COUNT(DISTINCT customer_id) AS distinct_customer_ids
FROM customer_data_quality_source_1000;
DESCRIBE customer_data_quality_source_1000;
DESCRIBE customer_data_quality_exceptions;
SELECT
    COUNT(*) AS total_exception_records,
    SUM(missing_email_flag) AS missing_email_records,
    SUM(invalid_signup_date_flag) AS invalid_signup_date_records,
    SUM(invalid_spend_flag) AS invalid_spend_records,
    SUM(duplicate_id_flag) AS duplicate_id_records
FROM customer_data_quality_exceptions;
SELECT
    (SELECT COUNT(*) FROM customer_data_quality_source_1000)
        AS total_source_records,
    (SELECT COUNT(*) FROM customer_data_quality_exceptions)
        AS exception_records,
    (SELECT COUNT(*) FROM customer_data_quality_source_1000)
      - (SELECT COUNT(*) FROM customer_data_quality_exceptions)
        AS records_without_flagged_exceptions;
        SELECT
    'Missing Email' AS issue_type,
    COUNT(*) AS affected_records
FROM customer_data_quality_source_1000
WHERE TRIM(COALESCE(email, '')) = ''

UNION ALL

SELECT
    'Invalid Signup Date',
    SUM(invalid_signup_date_flag)
FROM customer_data_quality_exceptions

UNION ALL

SELECT
    'Invalid Spend',
    SUM(invalid_spend_flag)
FROM customer_data_quality_exceptions

UNION ALL

SELECT
    'Duplicate Customer ID',
    SUM(duplicate_id_flag)
FROM customer_data_quality_exceptions;
SELECT 'Country' AS field_name, country AS raw_value,
       COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY country

UNION ALL

SELECT 'Segment', segment, COUNT(*)
FROM customer_data_quality_source_1000
GROUP BY segment

UNION ALL

SELECT 'Active Status', is_active, COUNT(*)
FROM customer_data_quality_source_1000
GROUP BY is_active

ORDER BY field_name, record_count DESC;
SELECT
    country AS raw_country,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY country
ORDER BY record_count DESC;

USE customer_data_quality;

CREATE TABLE customer_data_quality_standardized_v1 AS
SELECT
    customer_id,
    full_name,
    email,
    signup_date,
    country,
    spend,
    segment,
    is_active,

    CASE
        WHEN LOWER(TRIM(country)) IN ('germany', 'de')
            THEN 'Germany'
        WHEN LOWER(TRIM(country)) IN ('uk', 'united kingdom', 'gb')
            THEN 'United Kingdom'
        WHEN LOWER(TRIM(country)) IN ('u.s.', 'us', 'usa', 'united states')
            THEN 'United States'
        WHEN LOWER(TRIM(country)) IN ('brazil', 'br')
            THEN 'Brazil'
        WHEN LOWER(TRIM(country)) IN ('france', 'fr')
            THEN 'France'
        ELSE NULL
    END AS country_standardized,

    CASE
        WHEN LOWER(TRIM(segment)) IN ('enterprise', 'ent')
            THEN 'Enterprise'
        WHEN LOWER(TRIM(segment)) IN
            ('midmarket', 'mid-market', 'mid market')
            THEN 'Mid-Market'
        WHEN LOWER(TRIM(segment)) IN
            ('smb', 'small business')
            THEN 'SMB'
        WHEN LOWER(TRIM(segment)) = 'consumer'
            THEN 'Consumer'
        ELSE NULL
    END AS segment_standardized,

    CASE
        WHEN LOWER(TRIM(is_active)) IN ('1', 'true', 'y', 'yes')
            THEN 'Yes'
        WHEN LOWER(TRIM(is_active)) IN ('0', 'false', 'n', 'no')
            THEN 'No'
        ELSE NULL
    END AS active_status_standardized

FROM customer_data_quality_source_1000;
SELECT
    country_standardized,
    COUNT(*) AS record_count
FROM customer_data_quality_standardized_v1
GROUP BY country_standardized
ORDER BY record_count DESC;
SELECT
    segment_standardized,
    COUNT(*) AS record_count
FROM customer_data_quality_standardized_v1
GROUP BY segment_standardized
ORDER BY record_count DESC;
SELECT
    active_status_standardized,
    COUNT(*) AS record_count
FROM customer_data_quality_standardized_v1
GROUP BY active_status_standardized
ORDER BY record_count DESC;
SELECT
    is_active,
    LOWER(TRIM(is_active)) AS cleaned_value,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY is_active, LOWER(TRIM(is_active))
ORDER BY record_count DESC;
SELECT
    is_active,
    CASE
        WHEN LOWER(TRIM(is_active)) IN ('1', 'true', 'y', 'yes')
            THEN 'Yes'
        WHEN LOWER(TRIM(is_active)) IN ('0', 'false', 'n', 'no')
            THEN 'No'
        ELSE 'Review'
    END AS expected_status,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY is_active, expected_status
ORDER BY is_active;
SELECT
    is_active,
    HEX(is_active) AS raw_hex,
    LENGTH(is_active) AS value_length,
    LOWER(TRIM(is_active)) AS cleaned_value,
    LOWER(TRIM(is_active)) = 'true' AS true_test,
    LOWER(TRIM(is_active)) = 'false' AS false_test
FROM customer_data_quality_source_1000
WHERE is_active IS NOT NULL
LIMIT 15;
UPDATE customer_data_quality_standardized_v1
SET active_status_standardized =
    CASE
        WHEN LOWER(TRIM(
            REPLACE(REPLACE(is_active, CHAR(13), ''), CHAR(0), '')
        )) IN ('1', 'true', 'y', 'yes')
            THEN 'Yes'

        WHEN LOWER(TRIM(
            REPLACE(REPLACE(is_active, CHAR(13), ''), CHAR(0), '')
        )) IN ('0', 'false', 'n', 'no')
            THEN 'No'

        ELSE 'Review'
    END;




