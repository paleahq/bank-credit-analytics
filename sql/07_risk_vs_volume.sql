-- 7. Канал: объём против риска. Сравниваем approval rate с долей дефолтов 90+
WITH bad AS (
    SELECT l.loan_id, l.channel,
           MAX(CASE WHEN p.days_past_due >= 90 THEN 1 ELSE 0 END) AS is_bad90,
           MAX(CASE WHEN p.days_past_due >= 30 THEN 1 ELSE 0 END) AS is_bad30
    FROM loans l JOIN payments p ON p.loan_id = l.loan_id
    GROUP BY l.loan_id, l.channel
)
SELECT
    b.channel                                                      AS "Канал",
    COUNT(*)                                                       AS "Выдано кредитов",
    ROUND(100.0 * AVG(b.is_bad30), 1)                              AS "Просрочка 30+, %",
    ROUND(100.0 * AVG(b.is_bad90), 1)                              AS "Дефолт 90+, %",
    ROUND(AVG(l.principal))                                        AS "Средний чек, ₸",
    ROUND(SUM(CASE WHEN b.is_bad90 = 1 THEN l.principal ELSE 0 END) / 1000000.0, 1) AS "Объём в дефолте, млн ₸"
FROM bad b JOIN loans l ON l.loan_id = b.loan_id
GROUP BY 1
ORDER BY "Дефолт 90+, %" DESC;
