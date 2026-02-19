# AON — Performance Monitoring Dashboard

Dashboard di monitoraggio delle performance applicative di **Hygieia** su Appian.

> **Nota importante**: questo repository contiene **codice SAIL** da copiare
> manualmente in Appian Designer. Non è un package importabile (.zip).
> Seguire la guida in `docs/setup-guide.md`.

---

## Cosa fa

| Funzionalità | Descrizione |
|---|---|
| **Trend giornaliero** | Grafico a linee del tempo medio giornaliero (7/15/30/60/90 giorni configurabili) |
| **KPI Cards** | Media, Percentile 95°, processi attivi ora, errori nella finestra istantanea |
| **Real-time** | Finestra scorrevole (1/5/15/30 min): attivi, completati, errori per processo |
| **Dettaglio per processo** | Grid con avg, mediana, p95, min, max, error rate per ogni modello |
| **Alert processi bloccati** | Banner in dashboard + email automatica se un processo resta ACTIVE oltre la soglia |
| **Monitor schedulato** | Process Model a timer (ogni 15 min) che rileva blocchi e invia notifiche |

---

## Struttura del repository

```
/
├── README.md
├── config/
│   └── constants.yml              ← valori delle 5 costanti da creare in Appian
├── expression-rules/
│   ├── AON_PERF_formatDuration.sail
│   ├── AON_PERF_getProcessMetrics.sail
│   ├── AON_PERF_getDailyTrend.sail
│   ├── AON_PERF_getInstantMetrics.sail
│   └── AON_PERF_checkStuckProcesses.sail
├── interfaces/
│   ├── AON_PERF_Dashboard.sail
│   └── AON_PERF_AlertSettings.sail
├── process-models/
│   ├── AON_PERF_ScheduledMonitor.md   ← flusso + codice Script Task da incollare
│   └── AON_PERF_SendAlert.md
└── docs/
    └── setup-guide.md                 ← guida passo-passo
```

---

## Come si usa

Ogni file `.sail` contiene il codice da incollare nel campo corrispondente di Appian Designer:

| Tipo oggetto | Come crearlo in Appian | Dove incollare il codice |
|---|---|---|
| **Expression Rule** | Designer → New → Expression Rule | Tab "Definition" → campo espressione |
| **Interface** | Designer → New → Interface | Tab "Form" → campo "Form Expression" |
| **Process Model** | Designer → New → Process Model | Costruire manualmente il flusso, incollare i codici negli Script Task |
| **Constant** | Designer → New → Constant | Copiare tipo e valore da `config/constants.yml` |

**Prerequisito**: prima di creare le Expression Rule occorre creare il **Process Analytics Report (PAR)**. Vedere `docs/setup-guide.md §1`.

---

## Dipendenze tra oggetti

```
Costanti (5)
    │
    ▼
AON_PERF_formatDuration          ← nessuna dipendenza
    │
AON_PERF_getProcessMetrics       ← usa PAR + costanti
    ├──► AON_PERF_getDailyTrend   ← usa getProcessMetrics
    ├──► AON_PERF_getInstantMetrics
    └──► AON_PERF_checkStuckProcesses
              │
              ▼
    AON_PERF_Dashboard (Interface)    ← usa tutte le regole
    AON_PERF_AlertSettings (Interface)
              │
    AON_PERF_ScheduledMonitor (PM)    ← usa checkStuckProcesses
              └──► AON_PERF_SendAlert (PM)
```

**Ordine di creazione consigliato**: Costanti → PAR → formatDuration → getProcessMetrics → getDailyTrend, getInstantMetrics, checkStuckProcesses → Dashboard, AlertSettings → ScheduledMonitor → SendAlert

---

## Convenzioni di naming

Prefisso `AON_PERF_`:
- `AON_` — prefisso applicazione (Hygieia/AON)
- `PERF_` — modulo Performance Monitoring
- PascalCase per Interface e Process Model
- UPPER_CASE per Constants
