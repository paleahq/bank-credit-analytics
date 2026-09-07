import numpy as np, pandas as pd, sqlite3
from datetime import date, timedelta
rng = np.random.default_rng(42)

N_CLIENTS = 12000
START = date(2024,1,1); MONTHS = 24

regions = ['Алматы','Астана','Шымкент','Караганда','Актобе','Атырау','Павлодар','Костанай']
reg_p   = [.28,.22,.12,.09,.08,.08,.07,.06]
income  = ['до 200к','200-400к','400-700к','700к+']; inc_p=[.30,.38,.22,.10]
ages    = ['18-24','25-34','35-44','45-54','55+'];   age_p=[.14,.36,.28,.15,.07]

clients = pd.DataFrame({
 'client_id': np.arange(1, N_CLIENTS+1),
 'age_group': rng.choice(ages, N_CLIENTS, p=age_p),
 'region':    rng.choice(regions, N_CLIENTS, p=reg_p),
 'income_band':rng.choice(income, N_CLIENTS, p=inc_p),
})
clients['client_since'] = [ (date(2020,1,1)+timedelta(days=int(x))).isoformat()
                            for x in rng.integers(0, 2000, N_CLIENTS) ]
# активность клиента (тяжёлый хвост) и предпочитаемый продукт
act = rng.pareto(1.6, N_CLIENTS) + 0.25
client_w = act / act.sum()
pref_product = rng.choice(['POS-кредит','Кредит наличными','Кредитная карта'], N_CLIENTS, p=[.38,.34,.28])

channels = ['Отделение','Онлайн-заявка','Мобильное приложение','Партнёр (POS)','Колл-центр']
ch_p     = [.20,.26,.22,.24,.08]
products = ['POS-кредит','Кредит наличными','Кредитная карта']
pr_p     = [.38,.34,.28]

# базовые вероятности одобрения по каналу и доходу
appr_ch  = {'Отделение':.62,'Онлайн-заявка':.44,'Мобильное приложение':.51,'Партнёр (POS)':.58,'Колл-центр':.47}
appr_inc = {'до 200к':-.10,'200-400к':.0,'400-700к':.07,'700к+':.12}
appr_pr  = {'POS-кредит':.06,'Кредит наличными':-.05,'Кредитная карта':.0}
# take-up (клиент забрал деньги после одобрения)
take_ch  = {'Отделение':.86,'Онлайн-заявка':.62,'Мобильное приложение':.71,'Партнёр (POS)':.92,'Колл-центр':.66}

rows=[]; app_id=1
for m in range(MONTHS):
    month_start = date(2024,1,1) + timedelta(days=30*m)
    base = 1400 + 40*m + int(rng.normal(0,90))          # рост потока
    if month_start.month in (7,8): base = int(base*0.88) # летний спад
    if month_start.month == 12:    base = int(base*1.18)
    for _ in range(base):
        cid = int(rng.choice(N_CLIENTS, p=client_w)) + 1
        ch  = rng.choice(channels, p=ch_p)
        pr  = pref_product[cid-1] if rng.random() < 0.72 else rng.choice(products, p=pr_p)
        c   = clients.iloc[cid-1]
        apply_date = month_start + timedelta(days=int(rng.integers(0,28)))
        req = {'POS-кредит':rng.normal(280000,120000),
               'Кредит наличными':rng.normal(950000,420000),
               'Кредитная карта':rng.normal(500000,180000)}[pr]
        req = max(50000, round(req/10000)*10000)
        p = appr_ch[ch] + appr_inc[c.income_band] + appr_pr[pr]
        if c.age_group=='18-24': p-=.08
        if c.age_group=='55+':   p-=.05
        if req>1200000: p-=.10
        p = min(.93, max(.06, p))
        approved = rng.random() < p
        if approved:
            reason=None
            appr_amt = req if rng.random()<.72 else max(50000, round(req*rng.uniform(.5,.9)/10000)*10000)
            issued = rng.random() < take_ch[ch]
        else:
            reason = rng.choice(['Низкий скоринговый балл','Высокая долговая нагрузка',
                                 'Недостаточный подтверждённый доход','Действующая просрочка',
                                 'Недостаточная кредитная история','Несоответствие политике банка'],
                                 p=[.31,.24,.18,.12,.09,.06])
            appr_amt = 0; issued = False
        rows.append((app_id, cid, apply_date.isoformat(), ch, pr, int(req),
                     'Одобрено' if approved else 'Отказ', reason, int(appr_amt), int(issued)))
        app_id+=1

apps = pd.DataFrame(rows, columns=['app_id','client_id','apply_date','channel','product',
                                   'requested_amount','decision','reject_reason','approved_amount','is_issued'])

# --- выданные кредиты + платежи ---
iss = apps[apps.is_issued==1].copy().reset_index(drop=True)
iss['loan_id'] = np.arange(1, len(iss)+1)
term_map = {'POS-кредит':[6,12,18],'Кредит наличными':[12,24,36,48],'Кредитная карта':[12,24]}
iss['term_months'] = [int(rng.choice(term_map[p])) for p in iss['product']]
iss['rate'] = np.where(iss['product']=='POS-кредит', rng.normal(22,3,len(iss)),
              np.where(iss['product']=='Кредит наличными', rng.normal(28,4,len(iss)), rng.normal(34,3,len(iss)))).round(1)
loans = iss[['loan_id','app_id','client_id','product','channel','apply_date','approved_amount','term_months','rate']].rename(
        columns={'apply_date':'issue_date','approved_amount':'principal'})

# риск: у каждого кредита своя вероятность когда-либо уйти в просрочку 30+
inc_map = clients.set_index('client_id')['income_band'].to_dict()
risk_ch = {'Отделение':.070,'Партнёр (POS)':.095,'Мобильное приложение':.125,'Колл-центр':.140,'Онлайн-заявка':.170}
risk_inc= {'до 200к':.045,'200-400к':.010,'400-700к':-.020,'700к+':-.035}
risk_pr = {'POS-кредит':-.010,'Кредит наличными':.025,'Кредитная карта':.015}

pay=[]
for r in loans.itertuples():
    p_bad30 = min(.45, max(.02, risk_ch[r.channel] + risk_inc[inc_map[r.client_id]] + risk_pr[r.product]))
    bad30 = rng.random() < p_bad30
    roll90 = bad30 and (rng.random() < .38)
    first_miss = int(rng.integers(1, max(2, min(r.term_months, 13)))) if bad30 else 10**6
    d0 = date.fromisoformat(r.issue_date); dpd = 0; defaulted = False
    for k in range(1, r.term_months+1):
        due = d0 + timedelta(days=30*k)
        if due > date(2026,1,1): break
        if defaulted:
            dpd += 30; paid = 0
        elif k >= first_miss:
            if roll90 or (k - first_miss) < 1:
                dpd += 30; paid = 0
                if dpd >= 90 and roll90: defaulted = True
                if dpd >= 60 and not roll90: dpd = 0; paid = 1; first_miss = 10**6
            else:
                dpd = 0; paid = 1; first_miss = 10**6
        else:
            dpd = 0; paid = 1
        pay.append((r.loan_id, k, due.isoformat(), paid, dpd))
payments = pd.DataFrame(pay, columns=['loan_id','month_index','due_date','is_paid','days_past_due'])

# --- маркетинговые расходы по каналам ---
sp=[]
cost_ch = {'Отделение':9000,'Онлайн-заявка':4200,'Мобильное приложение':3100,'Партнёр (POS)':6400,'Колл-центр':5200}
for m in range(MONTHS):
    ms = (date(2024,1,1)+timedelta(days=30*m)).replace(day=1)
    for ch in channels:
        n = ((apps.apply_date.str[:7]==ms.isoformat()[:7]) & (apps.channel==ch)).sum()
        sp.append((ms.isoformat()[:7], ch, int(n*cost_ch[ch]*rng.uniform(.85,1.2))))
spend = pd.DataFrame(sp, columns=['month','channel','marketing_spend'])

for name,df in [('clients',clients),('applications',apps),('loans',loans),('payments',payments),('marketing_spend',spend)]:
    df.to_csv(f'data/{name}.csv', index=False)
con = sqlite3.connect('bank.db')
for name,df in [('clients',clients),('applications',apps),('loans',loans),('payments',payments),('marketing_spend',spend)]:
    df.to_sql(name, con, if_exists='replace', index=False)
con.close()
print({'clients':len(clients),'applications':len(apps),'loans':len(loans),'payments':len(payments)})
print('approval', round((apps.decision=='Одобрено').mean(),3), 'issue', round(apps.is_issued.mean(),3))
