-- 10. География: где объём, а где риск
WITH bad AS (
    SELECT l.loan_id, l.principal, c.region,
           MAX(CASE WHEN p.days_past_due >= 90 THEN 1 ELSE 0 END) AS is_bad90
    FROM loans l
    JOIN clients c  ON c.client_id = l.client_id
    JOIN payments p ON p.loan_id  = l.loan_id
    GROUP BY l.loan_id, l.principal, c.region
)
SELECT
    region                                                         AS "Регион",
    COUNT(*)                                                       AS "Кредитов",
    ROUND(SUM(principal) / 1000000.0, 1)                           AS "Объём, млн ₸",
    ROUND(AVG(principal))                                          AS "Средний чек, ₸",
    ROUND(100.0 * AVG(is_bad90), 1)                                AS "Дефолт 90+, %"
FROM bad
GROUP BY 1
ORDER BY "Объём, млн ₸" DESC;
