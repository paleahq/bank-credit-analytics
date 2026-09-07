-- 4. Причины отказов и их вес
SELECT
    reject_reason                                                  AS "Причина отказа",
    COUNT(*)                                                       AS "Отказов",
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)             AS "Доля, %",
    ROUND(AVG(requested_amount))                                   AS "Средний запрос, ₸"
FROM applications
WHERE decision = 'Отказ'
GROUP BY 1
ORDER BY "Отказов" DESC;
