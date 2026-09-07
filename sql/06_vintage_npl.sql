-- 6. Vintage-анализ: доля кредитов с просрочкой 30+ на 3, 6 и 12 месяце жизни
WITH cohort AS (
    SELECT loan_id, strftime('%Y-%m', issue_date) AS vintage FROM loans
),
mob AS (
    SELECT p.loan_id, c.vintage, p.month_index, p.days_past_due
    FROM payments p JOIN cohort c ON c.loan_id = p.loan_id
)
SELECT
    vintage                                                        AS "Когорта выдачи",
    COUNT(DISTINCT loan_id)                                        AS "Кредитов",
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN month_index <= 3  AND days_past_due >= 30 THEN loan_id END)
          / COUNT(DISTINCT loan_id), 1)                            AS "NPL30+ на 3 мес, %",
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN month_index <= 6  AND days_past_due >= 30 THEN loan_id END)
          / COUNT(DISTINCT loan_id), 1)                            AS "NPL30+ на 6 мес, %",
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN month_index <= 12 AND days_past_due >= 30 THEN loan_id END)
          / COUNT(DISTINCT loan_id), 1)                            AS "NPL30+ на 12 мес, %"
FROM mob
GROUP BY 1
HAVING COUNT(DISTINCT loan_id) > 300
ORDER BY 1;
