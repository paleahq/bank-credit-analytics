-- 8. Кросс-продажи: сколько клиентов берут второй продукт и как быстро
WITH ranked AS (
    SELECT client_id, product, issue_date,
           ROW_NUMBER() OVER (PARTITION BY client_id ORDER BY issue_date) AS n
    FROM loans
),
pairs AS (
    SELECT f.client_id, f.product AS first_product, s.product AS second_product,
           julianday(s.issue_date) - julianday(f.issue_date) AS days_gap
    FROM ranked f LEFT JOIN ranked s ON s.client_id = f.client_id AND s.n = 2
    WHERE f.n = 1
)
SELECT
    first_product                                                  AS "Первый продукт",
    COUNT(*)                                                       AS "Клиентов",
    SUM(CASE WHEN second_product IS NOT NULL THEN 1 ELSE 0 END)    AS "Взяли второй",
    ROUND(100.0 * SUM(CASE WHEN second_product IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS "Cross-sell rate, %",
    ROUND(AVG(days_gap))                                           AS "Дней до второго продукта"
FROM pairs
GROUP BY 1
ORDER BY "Cross-sell rate, %" DESC;
