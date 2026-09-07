-- 9. ABC-сегментация клиентов по объёму выдач (правило 80/15/5)
WITH totals AS (
    SELECT client_id, SUM(principal) AS volume, COUNT(*) AS loans_cnt
    FROM loans GROUP BY client_id
),
cum AS (
    SELECT client_id, volume, loans_cnt,
           SUM(volume) OVER (ORDER BY volume DESC ROWS UNBOUNDED PRECEDING)
             * 100.0 / SUM(volume) OVER () AS cum_share
    FROM totals
)
SELECT
    CASE WHEN cum_share <= 80 THEN 'A' WHEN cum_share <= 95 THEN 'B' ELSE 'C' END AS "Сегмент",
    COUNT(*)                                                       AS "Клиентов",
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)             AS "Доля клиентов, %",
    ROUND(SUM(volume) / 1000000.0, 1)                              AS "Объём, млн ₸",
    ROUND(100.0 * SUM(volume) / SUM(SUM(volume)) OVER (), 1)       AS "Доля объёма, %",
    ROUND(AVG(loans_cnt), 2)                                       AS "Кредитов на клиента"
FROM cum
GROUP BY 1
ORDER BY 1;
