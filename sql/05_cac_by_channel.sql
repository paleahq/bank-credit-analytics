-- 5. Стоимость привлечения: CPA по заявке и CAC по выданному кредиту
WITH app_stats AS (
    SELECT strftime('%Y-%m', apply_date) AS month, channel,
           COUNT(*) AS apps, SUM(is_issued) AS issued,
           SUM(CASE WHEN is_issued = 1 THEN approved_amount ELSE 0 END) AS volume
    FROM applications GROUP BY 1, 2
)
SELECT
    s.channel                                                      AS "Канал",
    SUM(m.marketing_spend) / 1000000.0                             AS "Расходы, млн ₸",
    SUM(s.apps)                                                    AS "Заявок",
    SUM(s.issued)                                                  AS "Выдано",
    ROUND(1.0 * SUM(m.marketing_spend) / SUM(s.apps))              AS "CPA заявки, ₸",
    ROUND(1.0 * SUM(m.marketing_spend) / NULLIF(SUM(s.issued), 0)) AS "CAC кредита, ₸",
    ROUND(100.0 * SUM(m.marketing_spend) / NULLIF(SUM(s.volume), 0), 2) AS "Расходы к объёму, %"
FROM app_stats s
JOIN marketing_spend m ON m.month = s.month AND m.channel = s.channel
GROUP BY 1
ORDER BY "CAC кредита, ₸";
