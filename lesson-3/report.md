# Звіт: Контейнеризація TorchScript-моделі (MobileNetV2)

## Підсумок (TL;DR)

- **mobilenet-fat:** розмір **11.6 GB**, шари (history) **11**, статус запуску — **OK**
- **mobilenet-slim:** розмір **11.1 GB**, шари (history) **16**, статус запуску — **OK**
- **Зменшення розміру:** **4.31%**
- **Час збірки:** fat **777 с**, slim **855 с**

---

## 1. Час збірки

- **fat:** 777 секунд
- **slim:** 855 секунд

> Multi-stage образ зазвичай будується довше, але дає менший runtime-розмір.

---

## 2. Розміри образів

- **mobilenet-fat:** 11.6 GB
- **mobilenet-slim:** 11.1 GB
- **Зменшення розміру:** 4.31%

---

## 3. Кількість шарів

(пораховано за `docker history`)

- **fat:** 11 шарів
- **slim:** 16 шарів

> За потреби «файлові» шари RootFS можна подивитись окремо:
> `docker image inspect <image> --format '{{ len .RootFS.Layers }}'`

---

## 4. Перевірка запуску — вивід top-3

**fat:**

- comic book: 0.0550
- electric fan: 0.0188
- disk brake: 0.0158

**slim:**

- comic book: 0.0550
- electric fan: 0.0188
- disk brake: 0.0158

---

## 5. Аналіз

### 5.1 Проблеми «жирного» образу (fat)

- База `ubuntu:22.04` + `apt` тягне великий базовий шар.
- Інструменти та службові утиліти (bash, coreutils, apt) не потрібні для inference.
- Великі RUN-кроки з `apt-get` і `pip` → значні гігабайтні шари.
- Навіть при очищенні кешів частина зайвого все одно потрапляє у фінальний шар.

### 5.2 Що зроблено в slim

- Multi-stage build: збірка залежностей окремо від мінімального runtime.
- У фінальному шарі лише Python-руттайм, залежності, `inference.py` і `model.pt`.
- Використання `--no-cache-dir`, мінімізація шарів, відсутність `apt` у runtime.

### 5.3 Поради щодо подальшої оптимізації

- Використати `venv` у builder і копіювати лише `/opt/venv` у runtime (менше, ніж увесь `/usr/local/lib`).
- Встановлювати **CPU-колеса** PyTorch:
  ```bash
  pip install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cpu torch torchvision
  ```
