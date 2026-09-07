-- 3. Approval rate: продукт x подтверждённый доход
SELECT
    a.product                                                      AS "Продукт",
    c.income_band                                                  AS "Доход",
    COUNT(*)                                                       AS "Заявок",
    ROUND(100.0 * SUM(CASE WHEN a.decision = 'Одобрено' THEN 1 ELSE 0 END) / COUNT(*), 1) AS "Approval rate, %",
    ROUND(AVG(a.requested_amount))                                 AS "Средний запрос, ₸"
FROM applications a
JOIN clients c ON c.client_id = a.client_id
GROUP BY 1, 2
HAVING COUNT(*) > 200
ORDER BY 1, 2;
