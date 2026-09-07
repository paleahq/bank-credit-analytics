-- 1. Воронка по каналам привлечения: заявка -> одобрение -> выдача
SELECT
    channel                                                        AS "Канал",
    COUNT(*)                                                       AS "Заявок",
    SUM(CASE WHEN decision = 'Одобрено' THEN 1 ELSE 0 END)         AS "Одобрено",
    SUM(is_issued)                                                 AS "Выдано",
    ROUND(100.0 * SUM(CASE WHEN decision = 'Одобрено' THEN 1 ELSE 0 END) / COUNT(*), 1) AS "Approval rate, %",
    ROUND(100.0 * SUM(is_issued)
          / NULLIF(SUM(CASE WHEN decision = 'Одобрено' THEN 1 ELSE 0 END), 0), 1)       AS "Take-up, %",
    ROUND(100.0 * SUM(is_issued) / COUNT(*), 1)                    AS "Заявка -> выдача, %"
FROM applications
GROUP BY channel
ORDER BY "Заявок" DESC;
