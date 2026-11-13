
-- ============================================================
-- CUSTOMER MASTER DATA QUALITY AUDIT
-- Final Exception View and Validation
-- ============================================================

CREATE OR REPLACE VIEW customer_data_quality_exceptions AS

WITH cleaned AS (
    SELECT
        customer_id,
        full_name,
        email,
        signup_date,
        country,
        spend,
        segment,
        is_active,

        LOWER(TRIM(
            REPLACE(
                REPLACE(COALESCE(signup_date, ''), CHAR(13), ''),
                CHAR(0), ''
            )
        )) AS date_norm,

        TRIM(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                UPPER(TRIM(COALESCE(spend, ''))),
                                CHAR(13), ''
                            ),
                            CHAR(0), ''
                        ),
                        'USD', ''
                    ),
                    '$', ''
                ),
                ',', ''
            )
        ) AS spend_norm

    FROM customer_data_quality_source_1000
),

parsed AS (
    SELECT
        *,

        CASE
            WHEN date_norm IN ('', 'null', 'none', 'n/a', '-', '-999')
                THEN NULL

            WHEN REGEXP_LIKE(date_norm, '^[0-9]+([.]0+)?$')
                 AND CAST(date_norm AS UNSIGNED) BETWEEN 1 AND 80000
                THEN DATE_ADD(
                    '1899-12-30',
                    INTERVAL CAST(date_norm AS UNSIGNED) DAY
                )

            ELSE COALESCE(
                STR_TO_DATE(date_norm, '%b %e, %Y'),
                STR_TO_DATE(date_norm, '%e %b %Y'),
                STR_TO_DATE(date_norm, '%d.%m.%Y'),
                STR_TO_DATE(date_norm, '%m.%d.%Y'),
                STR_TO_DATE(date_norm, '%m/%d/%Y'),
                STR_TO_DATE(date_norm, '%d-%b-%y'),
                STR_TO_DATE(date_norm, '%d-%m-%Y'),
                STR_TO_DATE(date_norm, '%d/%m/%Y'),
                STR_TO_DATE(date_norm, '%Y-%m-%d')
            )
        END AS parsed_signup_date,

        CASE
            WHEN spend_norm REGEXP '^-?[0-9]+([.][0-9]+)?$'
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
        WHEN TRIM(COALESCE(email, '')) = '' THEN 1
        ELSE 0
    END AS missing_email_flag,

    CASE
        WHEN parsed_signup_date IS NULL THEN 1
        ELSE 0
    END AS invalid_signup_date_flag,

    CASE
        WHEN spend_numeric IS NULL OR spend_numeric < 0 THEN 1
        ELSE 0
    END AS invalid_spend_flag,

    CASE
        WHEN customer_id IN (
            SELECT customer_id
            FROM customer_data_quality_source_1000
            GROUP BY customer_id
            HAVING COUNT(*) > 1
        ) THEN 1
        ELSE 0
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


-- ============================================================
-- VALIDATION: FINAL EXCEPTION COUNTS
-- ============================================================

SELECT
    COUNT(*) AS total_exception_records,
    SUM(missing_email_flag) AS missing_emails,
    SUM(invalid_signup_date_flag) AS invalid_dates,
    SUM(invalid_spend_flag) AS invalid_spend,
    SUM(duplicate_id_flag) AS duplicate_id_records
FROM customer_data_quality_exceptions;


-- ============================================================
-- VALIDATION: SIGNUP DATE EXCEPTIONS
-- ============================================================

SELECT
    customer_id,
    signup_date,
    parsed_signup_date,
    invalid_signup_date_flag
FROM customer_data_quality_exceptions
WHERE invalid_signup_date_flag = 1;
