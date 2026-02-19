# AON — Performance Monitoring Dashboard

Dashboard di monitoraggio delle performance applicative di **Hygieia** su Appian.

## Cosa fa

| Funzionalità | Descrizione |
|---|---|
| **Trend giornaliero** | Grafico a linee del tempo medio di esecuzione giorno per giorno (periodo configurabile: 7/15/30/60/90 giorni) |
| **KPI Cards** | Media, Percentile 95°, processi attivi ora, errori nell'ultima finestra |
| **Real-time** | Finestra scorrevole (1/5/15/30 min): attivi, completati, errori per processo |
| **Dettaglio per processo** | Grid ordinabile con avg, mediana, p95, min, max, error rate per ogni modello |
| **Alert processi bloccati** | Banner visivo in dashboard + email automatica se un processo rimane ACTIVE oltre la soglia |
| **Monitor schedulato** | Process Model che gira ogni 15 minuti e invia email se rileva processi bloccati |

---

## Oggetti inclusi nel package

### Constants
| Nome | Tipo | Default | Descrizione |
|---|---|---|---|
| `AON_PERF_DEFAULT_TREND_DAYS` | Integer | 30 | Giorni di storico mostrati di default |
| `AON_PERF_STUCK_THRESHOLD_MINS` | Integer | 60 | Minuti oltre cui un processo è "bloccato" |
| `AON_PERF_ALERT_RECIPIENTS` | Text | — | Email destinatari alert (separati da `;`) |
| `AON_PERF_MONITORED_PROCESS_MODELS` | Text (JSON) | — | Array JSON dei processi critici monitorati |
| `AON_PERF_PAR_EXECUTION_TIMES` | Text | — | UUID del Process Analytics Report (**da configurare**) |

### Expression Rules
| Nome | Descrizione |
|---|---|
| `AON_PERF_formatDuration` | Converte secondi in stringa leggibile (es. `2h 14m 03s`) |
| `AON_PERF_getProcessMetrics` | Statistiche aggregate (avg, mediana, p95, min, max, error rate) per periodo |
| `AON_PERF_getDailyTrend` | Trend giornaliero formattato per grafico a linee |
| `AON_PERF_getInstantMetrics` | Metriche istantanee degli ultimi N minuti |
| `AON_PERF_checkStuckProcesses` | Lista processi ACTIVE bloccati oltre soglia |

### Interfaces
| Nome | Descrizione |
|---|---|
| `AON_PERF_Dashboard` | Dashboard principale con tutti i pannelli |
| `AON_PERF_AlertSettings` | Configurazione soglie, destinatari e lista processi critici |

### Process Models
| Nome | Trigger | Descrizione |
|---|---|---|
| `AON_PERF_ScheduledMonitor` | Timer ogni 15 min | Controlla processi bloccati e avvia invio alert |
| `AON_PERF_SendAlert` | Subprocess | Invia email di notifica, opzionalmente logga su data store |

---

## Prerequisiti

### 1. Creare il Process Analytics Report (PAR)

Questo è il passaggio più importante. Il PAR è l'oggetto Appian che espone i dati di esecuzione dei processi alle Expression Rules.

1. In Appian Designer, vai su **Reports** → **New Report** → **Process Report**
2. Configura le colonne nell'ordine esatto seguente:

| Colonna | Campo Appian | Tipo |
|---|---|---|
| `c1` | Process Name | Text |
| `c2` | Process Model Name | Text |
| `c3` | Start Time | Date and Time |
| `c4` | Completion Time | Date and Time |
| `c5` | Elapsed Time (secondi) | Number |
| `c6` | Status | Text |
| `c7` | Initiator | Text |

3. Salva il report con nome es. `AON PERF - Execution Times`
4. Copia l'UUID dall'URL: `/suite/rest/a/applications/latest/self/report/**{UUID}**`
5. Aggiorna la costante `AON_PERF_PAR_EXECUTION_TIMES` con questo UUID

> **Nota su "Elapsed Time"**: in Appian 23.x il campo si chiama "Elapsed time" o "Duration".
> In versioni precedenti potrebbe non esistere e va calcolato come:
> `dateTimeToMilliseconds(completionTime) - dateTimeToMilliseconds(startTime)) / 1000`
> In questo caso modificare `AON_PERF_getProcessMetrics` di conseguenza.

### 2. Configurare le Constants

Aggiornare i valori dopo l'importazione:

```
AON_PERF_ALERT_RECIPIENTS        → "nome@azienda.it;altro@azienda.it"
AON_PERF_MONITORED_PROCESS_MODELS → '["Invio Mail","Sincronizzazione Dati","..."]'
AON_PERF_PAR_EXECUTION_TIMES     → "UUID-del-PAR-creato-sopra"
AON_PERF_STUCK_THRESHOLD_MINS    → 60  (adattare per ambiente)
```

### 3. Attivare il Process Model schedulato

1. Importare `AON_PERF_ScheduledMonitor`
2. Aprire il Process Model in Appian Designer
3. Configurare lo **Start Event** come **Timer Event**:
   - Tipo: Recurring
   - Intervallo: ogni **15 minuti**
4. Verificare che il Service Account abbia:
   - Accesso al PAR configurato
   - Permessi per l'invio email

### 4. Aggiungere la Dashboard al sito

1. Aprire il Site Appian di Hygieia in Designer
2. Aggiungere una nuova pagina:
   - Tipo: **Interface**
   - Interface: `AON_PERF_Dashboard`
   - Titolo pagina: "Performance Monitoring"
3. Opzionalmente aggiungere anche `AON_PERF_AlertSettings` come pagina admin

---

## Architettura del flusso dati

```
Appian Process Engine
        │
        ▼
Process Analytics Report (PAR)   ←── configurato manualmente
        │
        ├──► AON_PERF_getProcessMetrics   ──► statistiche periodo
        ├──► AON_PERF_getDailyTrend       ──► dati grafico
        ├──► AON_PERF_getInstantMetrics   ──► real-time ultimi N min
        └──► AON_PERF_checkStuckProcesses ──► processi bloccati
                        │
                        ▼
              AON_PERF_Dashboard  (Interface)
                        │
              AON_PERF_ScheduledMonitor  (Timer ogni 15 min)
                        │
                        └──► AON_PERF_SendAlert  ──► Email destinatari
```

---

## Estensioni future

- **Integrazioni**: Aggiungere una sezione per i tempi delle Connected System integration calls (richiede logging custom o plugin Appian Monitoring)
- **Viste utente**: Tracciare i tempi di caricamento delle interfacce tramite log custom scritto al `onLoad` delle interface
- **Export CSV/PDF**: Collegare il pulsante "Esporta Report" a un Process Model che genera il documento
- **Alert su soglie di tempo**: Oltre ai processi bloccati, avvisare se il tempo medio supera una soglia configurabile
- **Dashboard Grafana**: Esportare le metriche via Appian Web API verso sistemi di monitoring esterni

---

## Convenzioni di naming

Tutti gli oggetti seguono il prefisso `AON_PERF_`:
- `AON_` = prefisso applicazione (AON/Hygieia)
- `PERF_` = modulo Performance Monitoring
- Nome oggetto in PascalCase per interfacce/PM, UPPER_CASE per costanti
