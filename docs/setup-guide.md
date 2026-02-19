# Guida all'installazione — AON Performance Monitoring Dashboard

## Prerequisiti

- Appian 21.x o superiore
- Accesso da amministratore all'ambiente Appian di destinazione
- Accesso al modulo **Process Analytics** abilitato
- Un Service Account con permessi di esecuzione processi e invio email

---

## Passo 1 — Creare il Process Analytics Report (PAR)

Questo è il prerequisito più importante. Il PAR è il "ponte" tra
Appian e le expression rule del package.

1. Accedere ad Appian Designer → **Reports** → **New Process Report**
2. Configurare il report con **esattamente** queste 7 colonne nell'ordine indicato:

   | Posizione | Campo Appian              | Nome visualizzato     | Tipo         |
   |-----------|---------------------------|-----------------------|--------------|
   | c1        | Process Name              | Nome Istanza          | Text         |
   | c2        | Process Model Name        | Modello di Processo   | Text         |
   | c3        | Start Time                | Data Avvio            | DateTime     |
   | c4        | Completion Time           | Data Completamento    | DateTime     |
   | c5        | Elapsed Time (seconds)    | Durata (secondi)      | Integer      |
   | c6        | Status                    | Stato                 | Text         |
   | c7        | Initiator                 | Avviatore             | Text         |

   > **Nota**: "Elapsed Time in seconds" potrebbe chiamarsi diversamente
   > a seconda della versione di Appian. Cercare "Duration", "Execution Time"
   > o "Elapsed Time" nelle colonne disponibili.
   > Se disponibile solo in millisecondi, adattare le expression rule
   > dividendo per 1000.

3. Impostare il report come **visibile a tutti** (o al gruppo appropriato)
4. Annotare l'**UUID** del report dall'URL della pagina:
   ```
   /suite/rest/a/applications/latest/self/report/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ```

---

## Passo 2 — Importare il package

1. In Appian Designer → **Apps** → **Import Package**
2. Selezionare il file ZIP del package (generato dalla repo)
   oppure importare i singoli oggetti XML dall'IDE
3. Risolvere eventuali conflitti di naming (aggiungere prefisso ambiente
   se necessario, es. `DEV_AON_PERF_`)

---

## Passo 3 — Configurare le Costanti

Dopo l'importazione, aggiornare le seguenti costanti in Appian Designer:

| Costante                            | Valore da impostare                                    |
|-------------------------------------|--------------------------------------------------------|
| `AON_PERF_PAR_EXECUTION_TIMES`      | UUID del PAR creato al Passo 1                         |
| `AON_PERF_DEFAULT_TREND_DAYS`       | Giorni default (es. `30`)                              |
| `AON_PERF_STUCK_THRESHOLD_MINS`     | Soglia minuti blocco processo (es. `60` per PROD)      |
| `AON_PERF_ALERT_RECIPIENTS`         | Email destinatari separati da `;`                      |
| `AON_PERF_MONITORED_PROCESS_MODELS` | Array JSON con nomi processi critici (vedi sotto)      |

### Formato `AON_PERF_MONITORED_PROCESS_MODELS`

```json
["Invio Mail", "Sincronizzazione Dati", "Generazione Report", "Import Anagrafiche"]
```

Inserire i **nomi esatti** come appaiono nel campo "Process Model Name"
del Process Analytics Report.

---

## Passo 4 — Configurare il Process Model schedulato

1. Aprire `AON_PERF_ScheduledMonitor` in Appian Process Modeler
2. Configurare il **Start Event Timer**:
   - Tipo: **Timer** → **Recurring**
   - Intervallo: **ogni 15 minuti** (o 30 per ambienti meno critici)
   - Fuso orario: Europe/Rome (o quello dell'ambiente)
3. Verificare che il Service Account abbia:
   - Accesso in lettura al PAR
   - Permesso di avvio processi
   - Permesso di invio email

4. **Attivare** il process model (Status → Active)

---

## Passo 5 — Aggiungere la Dashboard al Sito

1. Accedere al **Sito Appian** di riferimento (es. portale Hygieia)
2. Aggiungere una nuova pagina:
   - Tipo: **Interface**
   - Oggetto: `AON_PERF_Dashboard`
   - Nome pagina: "Performance" o "Monitoraggio"
   - Visibilità: gruppo amministratori/operations
3. (Opzionale) Aggiungere anche `AON_PERF_AlertSettings` come
   pagina separata accessibile solo agli amministratori

---

## Passo 6 — Test iniziale

1. Aprire la dashboard: verificare che i dati vengano caricati
2. Controllare il PAR: se la griglia è vuota, verificare l'UUID in
   `AON_PERF_PAR_EXECUTION_TIMES`
3. Avviare manualmente `AON_PERF_ScheduledMonitor` per testare
   il sistema di alerting
4. Verificare la ricezione dell'email di test

---

## Troubleshooting

### La dashboard mostra dati vuoti
- Verificare che il PAR abbia dati (aprirlo direttamente in Appian)
- Verificare che `AON_PERF_PAR_EXECUTION_TIMES` contenga l'UUID corretto
- Verificare i permessi del Service Account sul PAR

### "Elapsed Time" non disponibile nel PAR
In alcune versioni Appian, il tempo di esecuzione non è una colonna
diretta. Alternativa: usare la colonna calcolata con espressione:
```
dateTimeToMilliseconds(completionTime) - dateTimeToMilliseconds(startTime)
```
e dividere per 1000 per ottenere i secondi.
Aggiornare di conseguenza la expression rule `AON_PERF_getProcessMetrics`.

### Nessuna email ricevuta
- Verificare la configurazione SMTP di Appian (Admin Console → Email)
- Verificare `AON_PERF_ALERT_RECIPIENTS` (nessuno spazio dopo `;`)
- Controllare i log del processo `AON_PERF_SendAlert`

### Il monitor schedulato non si avvia
- Verificare che il PM sia in stato **Active**
- Verificare che il Service Account abbia i permessi di avvio
- Controllare i log di sistema Appian (Admin Console → Logs)
