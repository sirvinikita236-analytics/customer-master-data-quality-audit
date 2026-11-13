SELECT
    active_status_standardized,
    COUNT(*) AS record_count
FROM customer_data_quality_standardized_v1
GROUP BY active_status_standardized;
SELECT
    active_status_standardized,
    COUNT(*) AS record_count
FROM customer_data_quality_standardized_v1
GROUP BY active_status_standardized;
SELECT
    CONCAT('[', is_active, ']') AS raw_value,
    HEX(is_active) AS raw_hex,
    LENGTH(is_active) AS raw_length,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY is_active, HEX(is_active), LENGTH(is_active)
ORDER BY record_count DESC;
SELECT
    HEX(is_active) AS raw_hex,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY HEX(is_active)
ORDER BY record_count DESC;
UPDATE customer_data_quality_standardized_v1
SET active_status_standardized =
    CASE
        WHEN LOWER(TRIM(REPLACE(is_active, CHAR(13), '')))
             IN ('1', 'true', 'y', 'yes') THEN 'Yes'
        WHEN LOWER(TRIM(REPLACE(is_active, CHAR(13), '')))
             IN ('0', 'false', 'n', 'no') THEN 'No'
        ELSE 'Review'
    END;
    SET SQL_SAFE_UPDATES = 0;
    UPDATE customer_data_quality_standardized_v1
SET active_status_standardized =
    CASE
        WHEN LOWER(TRIM(REPLACE(is_active, CHAR(13), '')))
             IN ('1', 'true', 'y', 'yes') THEN 'Yes'
        WHEN LOWER(TRIM(REPLACE(is_active, CHAR(13), '')))
             IN ('0', 'false', 'n', 'no') THEN 'No'
        ELSE 'Review'
    END;
    SET SQL_SAFE_UPDATES = 1;
    SELECT active_status_standardized, COUNT(*) AS record_count
FROM customer_data_quality_standardized_v1
GROUP BY active_status_standardized;
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
    COUNT(*) AS total_records,
    SUM(country_standardized IS NULL) AS missing_country,
    SUM(segment_standardized IS NULL) AS missing_segment,
    SUM(active_status_standardized IS NULL) AS missing_active_status
FROM customer_data_quality_standardized_v1;
SELECT
    COUNT(*) AS total_records,
    SUM(parsed_signup_date IS NOT NULL) AS valid_dates,
    SUM(parsed_signup_date IS NULL) AS invalid_dates,
    SUM(spend_numeric IS NOT NULL) AS valid_spend,
    SUM(spend_numeric IS NULL) AS invalid_spend
FROM customer_data_quality_exceptions;
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS distinct_customer_ids
FROM customer_data_quality_exceptions;
SELECT
    customer_id,
    COUNT(*) AS occurrence_count
FROM customer_data_quality_exceptions
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;
SELECT 
    COUNT(*) AS duplicate_id_groups,
    SUM(occurrence_count) AS records_with_duplicate_ids,
    SUM(occurrence_count - 1) AS extra_duplicate_records
FROM
    (SELECT 
        customer_id, COUNT(*) AS occurrence_count
    FROM
        customer_data_quality_exceptions
    WHERE
        customer_id IS NOT NULL
            AND TRIM(customer_id) <> ''
    GROUP BY customer_id
    HAVING COUNT(*) > 1) AS duplicates;
    SELECT
    COUNT(*) AS exception_records,
    SUM(missing_email_flag) AS missing_email_records
FROM customer_data_quality_exceptions;
SELECT
    COUNT(*) AS total_records,
    SUM(
        CASE
            WHEN email IS NULL OR TRIM(email) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_emails
FROM customer_data_quality_source_1000;
SELECT
    COUNT(*) AS total_records,
    SUM(
        CASE
            WHEN spend IS NULL
              OR TRIM(spend) = ''
              OR LOWER(TRIM(spend)) IN ('null', 'n/a', 'na', 'missing')
            THEN 1 ELSE 0
        END
    ) AS missing_or_placeholder_spend
FROM customer_data_quality_source_1000;
SELECT
    spend,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
WHERE spend IS NOT NULL
  AND TRIM(REPLACE(spend, CHAR(13), '')) <> ''
GROUP BY spend
ORDER BY record_count DESC;
SELECT
    CASE
        WHEN spend IS NULL
          OR TRIM(spend) = ''
          OR LOWER(TRIM(spend)) IN ('null', 'n/a', 'na', 'missing')
            THEN 'Missing / Placeholder'

        WHEN CAST(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(LOWER(TRIM(spend)), 'usd', ''),
                    '$', ''),
                ',', ''),
            CHAR(13), '') AS DECIMAL(15,2)
        ) < 0
            THEN 'Negative Spend'

        WHEN REPLACE(
                 REPLACE(
                     REPLACE(
                         REPLACE(LOWER(TRIM(spend)), 'usd', ''),
                     '$', ''),
                 ',', ''),
             CHAR(13), '') REGEXP '^[0-9]+(\\.[0-9]+)?$'
            THEN 'Valid Numeric Spend'

        ELSE 'Invalid Spend Format'
    END AS spend_category,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY spend_category
ORDER BY record_count DESC;
SELECT spend, COUNT(*) AS record_count
FROM customer_data_quality_source_1000
WHERE spend IS NOT NULL
  AND TRIM(spend) <> ''
  AND LOWER(TRIM(spend)) NOT IN ('null', 'n/a', 'na', 'missing')
  AND REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(LOWER(TRIM(spend)), 'usd', ''),
          '$', ''),
        ',', ''),
      CHAR(13), '') NOT REGEXP '^[0-9]+(\\.[0-9]+)?$'
GROUP BY spend
LIMIT 15;
SELECT
    CASE
        WHEN cleaned_spend IS NULL
          OR cleaned_spend = ''
          OR cleaned_spend IN ('null', 'n/a', 'na', 'missing')
            THEN 'Missing / Placeholder'

        WHEN cleaned_spend REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
             AND CAST(cleaned_spend AS DECIMAL(15,2)) < 0
            THEN 'Negative Spend'

        WHEN cleaned_spend REGEXP '^[0-9]+(\\.[0-9]+)?$'
            THEN 'Valid Numeric Spend'

        ELSE 'Invalid Spend Format'
    END AS spend_category,
    COUNT(*) AS record_count
FROM (
    SELECT
        TRIM(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(LOWER(TRIM(spend)), CHAR(13), ''),
                        'usd', ''
                    ),
                    '$', ''
                ),
                ',', ''
            )
        ) AS cleaned_spend
    FROM customer_data_quality_source_1000
) AS cleaned_data
GROUP BY spend_category
ORDER BY record_count DESC;
SELECT
    signup_date,
    COUNT(*) AS record_count
FROM customer_data_quality_source_1000
GROUP BY signup_date
ORDER BY record_count DESC
LIMIT 20;
SELECT
    COUNT(*) AS total_records,
    SUM(parsed_signup_date IS NOT NULL) AS parsed_dates,
    SUM(parsed_signup_date IS NULL) AS unparsed_dates
FROM customer_data_quality_exceptions;
SELECT
    signup_date,
    COUNT(*) AS record_count
FROM customer_data_quality_exceptions
WHERE parsed_signup_date IS NULL
  AND LOWER(TRIM(signup_date)) NOT IN
      ('n/a', 'none', 'null', '-', '-999', '')
GROUP BY signup_date
ORDER BY record_count DESC
LIMIT 20;
SELECT
    COUNT(*) AS dd_mm_yyyy_records
FROM customer_data_quality_source_1000
WHERE TRIM(REPLACE(signup_date, CHAR(13), ''))
      REGEXP '^[0-9]{2}\\.[0-9]{2}\\.[0-9]{4}$';
      SELECT
    signup_date,
    STR_TO_DATE(TRIM(signup_date), '%d.%m.%Y') AS parsed_date
FROM customer_data_quality_source_1000
WHERE TRIM(signup_date) REGEXP '^[0-9]{2}\\.[0-9]{2}\\.[0-9]{4}$'
LIMIT 5;
SHOW CREATE VIEW customer_data_quality_exceptions;
SELECT
    COUNT(*) AS total_records,
    SUM(
        STR_TO_DATE(
            TRIM(REPLACE(signup_date, CHAR(13), '')),
            '%d.%m.%Y'
        ) IS NOT NULL
    ) AS parsed_dd_mm_yyyy
FROM customer_data_quality_source_1000
WHERE TRIM(signup_date)
      REGEXP '^[0-9]{2}\\.[0-9]{2}\\.[0-9]{4}$';
      SHOW CREATE VIEW customer_data_quality_exceptions;