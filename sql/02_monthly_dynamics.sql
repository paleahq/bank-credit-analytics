-- 2. Помесячная динамика: поток заявок, выдачи, объём и средний чек
SELECT
    strftime('%Y-%m', apply_date)                                  AS "Месяц",
    COUNT(*)                                                       AS "Заявок",
    SUM(is_issued)                                                 AS "Выдано",
    ROUND(100.0 * SUM(is_issued) / COUNT(*), 1)                    AS "Конверсия, %",
    ROUND(SUM(CASE WHEN is_issued = 1 THEN approved_amount END) / 1000000.0, 1) AS "Объём выдач, млн ₸",
    ROUND(AVG(CASE WHEN is_issued = 1 THEN approved_amount END))   AS "Средний чек, ₸"
FROM applications
GROUP BY 1
ORDER BY 1;
