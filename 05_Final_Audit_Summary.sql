SELECT
    'Total Source Records' AS audit_metric,
    COUNT(*) AS record_count,
    100.00 AS percentage
FROM customer_data_quality_source_1000

UNION ALL

SELECT
    'Unique Exception Records',
    COUNT(*),
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM customer_data_quality_source_1000), 2
    )
FROM customer_data_quality_exceptions

UNION ALL

SELECT
    'Missing Emails',
    SUM(missing_email_flag),
    ROUND(
        SUM(missing_email_flag) * 100.0 /
        (SELECT COUNT(*) FROM customer_data_quality_source_1000), 2
    )
FROM customer_data_quality_exceptions

UNION ALL

SELECT
    'Invalid Signup Dates',
    SUM(invalid_signup_date_flag),
    ROUND(
        SUM(invalid_signup_date_flag) * 100.0 /
        (SELECT COUNT(*) FROM customer_data_quality_source_1000), 2
    )
FROM customer_data_quality_exceptions

UNION ALL

SELECT
    'Invalid Spend',
    SUM(invalid_spend_flag),
    ROUND(
        SUM(invalid_spend_flag) * 100.0 /
        (SELECT COUNT(*) FROM customer_data_quality_source_1000), 2
    )
FROM customer_data_quality_exceptions

UNION ALL

SELECT
    'Duplicate ID Records',
    SUM(duplicate_id_flag),
    ROUND(
        SUM(duplicate_id_flag) * 100.0 /
        (SELECT COUNT(*) FROM customer_data_quality_source_1000), 2
    )
FROM customer_data_quality_exceptions;
