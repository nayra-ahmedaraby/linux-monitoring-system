# 🎯 Linux Monitoring System — Cheat Sheet

كل اللي محتاجه في صفحة واحدة. خد نفس عميق — البروجكت أبسط مما يبدو.

---

## 🧠 الفكرة في 30 ثانية

نظام بيقيس حالة سيرفر Linux ويعرضها بشكل ملوّن. مكوّن من 4 طبقات:

```
M1: يقيس الموارد         (CPU, RAM, Disk, Network)
M2: يفحص الأمن            (services, ssh, ports, files)
M3: يعرض كل شيء (أنا)     (dashboard, menu, controller)
M4: يسجّل ويلخّص          (logs, alerts, daily reports)
```

كل سكريپت يطبع سطر بصيغة موحّدة:
```
NAME|VALUE|STATUS|TIMESTAMP
```

---

## ⚡ 5 أوامر هي اللي محتاجاهم

```bash
./install.sh              # مرة واحدة بس - تجهيز

./monitor.sh --menu       # القائمة التفاعلية (للـ demo) ⭐

./monitor.sh --once       # snapshot سريعة

./monitor.sh --alerts     # فحص + تنبيهات

./monitor.sh --help       # كل الخيارات
```

---

## 🎬 سيناريو الـ Demo (5 دقايق)

```bash
# 1. افتحي القائمة
./monitor.sh --menu

# 2. اشرحي:
"النظام يعرض metrics من Linux في dashboard ملوّن"

# 3. اختاري 1 (Snapshot) — اشرحي:
   "كل سطر = metric. الألوان = OK أخضر، WARN أصفر، CRITICAL أحمر"
   "العتبات في config.conf — ممكن تتعدّل"

# 4. اختاري 2 (Watch) — اشرحي:
   "بيتحدّث كل 5 ثواني. مفيد للمراقبة الحية"
   اضغطي Ctrl+C للخروج

# 5. اختاري 3 (Alerts) — اشرحي:
   "يفحص كل شيء ويسجّل في log"
   "بيكتب في /var/log/sysmonitor/alerts.log"

# 6. اختاري 5 (Daily Report) — اشرحي:
   "ملخص لكل ما حصل في اليوم — يقرأ من الـ logs"

# 7. اختاري q للخروج
```

---

## 📁 الملفات المهمة (12 ملف فقط)

| الملف | المسؤولية | اللي بتقوله للدكتور |
|---|---|---|
| `monitor.sh` | الـ entry point | "ده اللي تبدأ منه" |
| `config.conf` | الإعدادات | "كل العتبات في ملف واحد" |
| `install.sh` | التركيب | "تشييك على الأدوات وإنشاء المجلدات" |
| `scripts/resources/cpu.sh` | قياس CPU | "بيستخدم top" |
| `scripts/resources/memory.sh` | قياس RAM | "بيستخدم free" |
| `scripts/resources/disk.sh` | قياس Disk | "بيستخدم df" |
| `scripts/security/services.sh` | فحص الخدمات | "بيستخدم systemctl" |
| `scripts/security/file_integrity.sh` | تكامل الملفات | "MD5 hash + مقارنة" |
| `scripts/ui/dashboard.sh` | عرض الـ dashboard | "يقرأ format ويلوّن" |
| `scripts/ui/menu.sh` | القائمة التفاعلية | "while + case" |
| `scripts/logging/alerts.sh` | محرك التنبيهات | "يفحص ويكتب logs" |
| `scripts/logging/daily_report.sh` | التقرير اليومي | "يقرأ logs ويلخّص" |

الباقي helpers (log_rotate, log_writer, colors, progress_bar).

---

## 🎯 أهم 3 مفاهيم

### 1. الـ Output Contract الموحّد
كل سكريپت metric يطبع:
```
NAME|VALUE|STATUS|TIMESTAMP
```
ده اللي يخلّي الـ dashboard يقدر يقرا من أي سكريپت.

### 2. Source — تحميل الإعدادات
```bash
source config.conf    # يحمّل المتغيرات من ملف خارجي
```
ده اللي يخلّي العتبات مركزية.

### 3. Pipe و Process Substitution
```bash
ls | wc -l                          # pipe (subshell)
while read line; do ...; done < <(ls)   # process substitution (main shell)
```
المهم: الـ process substitution لازمة لما عاوزة المتغيرات تفضل بعد الـ loop.

---

## 🚨 لو حصلت مشكلة في الـ demo

| المشكلة | الحل السريع |
|---|---|
| السكريپت ما يشتغلش | `bash script.sh` بدل `./script.sh` |
| ألوان غريبة | جرّبي terminal مختلف |
| مفيش output | اعملي `./install.sh` تاني |
| Permission denied | `chmod +x file.sh` |

---

## 💡 لو الدكتور سأل

> **س:** ليه استخدمتوا bash مش Python؟
> **ج:** المشروع متخصص في Linux administration. Bash هي اللغة الـ native للنظام، تستخدم الأدوات الـ built-in مباشرة.

> **س:** إيه الفرق بين dashboard و alerts؟
> **ج:** Dashboard للعرض الفوري — Alerts للسجل الدائم.

> **س:** ليه استخدمتوا config.conf؟
> **ج:** Separation of configuration from code. تغيير عتبة لا يحتاج تعديل سكريپت.

> **س:** إزاي يشتغل على توزيعات مختلفة؟
> **ج:** عملنا fallback في الكود (cron/crond, ssh/sshd, auth.log/secure).

> **س:** إيه ميزة الـ Output Contract؟
> **ج:** Loose coupling. أي عضو يقدر يعدّل سكريپته بدون كسر الباقي.

---

## ✅ Checklist قبل الـ Demo

- [ ] `./install.sh` تم بنجاح
- [ ] `./monitor.sh --menu` يفتح القائمة
- [ ] الخيار 1 يعرض dashboard
- [ ] الخيار 3 يشغّل alerts
- [ ] sshd شغّال: `sudo systemctl enable --now ssh`
- [ ] مفيش errors واضحة

---

**خد نفس. البروجكت شغّال. أنتي جاهزة.** 💪
