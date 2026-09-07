import sqlite3, pandas as pd, glob, os, re
con = sqlite3.connect('bank.db')
out = ["# Результаты запросов\n",
       "Ниже — вывод каждого запроса из папки `sql/`. Данные синтетические, сгенерированы скриптом `gen.py`.\n"]
for f in sorted(glob.glob('sql/*.sql')):
    q = open(f).read()
    title = re.search(r'--\s*(.+)', q).group(1).strip()
    df = pd.read_sql_query(q, con)
    out.append(f"\n## {title}\n\n`{os.path.basename(f)}`\n")
    show = df.head(14)
    out.append(show.to_markdown(index=False, floatfmt=",.1f"))
    if len(df) > 14: out.append(f"\n_...ещё {len(df)-14} строк_")
    out.append("")
open('results/RESULTS.md','w').write("\n".join(out))
print("\n".join(out)[:6000])
