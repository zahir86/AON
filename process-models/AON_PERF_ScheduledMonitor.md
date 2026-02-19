# AON_PERF_ScheduledMonitor — Process Model

Process Model schedulato per il rilevamento automatico di processi bloccati.

## Configurazione del timer

Nel **Start Event** impostare:
- Tipo evento: **Timer** → **Recurring**
- Frequenza: **ogni 15 minuti**
- Fuso orario: `Europe/Rome`

## Flusso del processo

```
[Start Timer]
     │
     ▼
[Script Task: Controlla processi bloccati]
     │
     ▼
[Gateway XOR]
     ├── hasStuck = true  ──► [Script Task: Prepara corpo email]
     │                              │
     │                              ▼
     │                        [Call Activity: AON_PERF_SendAlert]
     │                              │
     └── hasStuck = false ──────────┤
                                    ▼
                               [End Event]
```

## Variabili di processo

| Variabile      | Tipo       | Descrizione                          |
|----------------|------------|--------------------------------------|
| `pv!stuckResult` | Dictionary | Output di `AON_PERF_checkStuckProcesses` |
| `pv!alertBody`   | Text       | Corpo email formattato               |

## Codice Script Task 1 — "Controlla processi bloccati"

```
a!save(
  pv!stuckResult,
  rule!AON_PERF_checkStuckProcesses(
    thresholdMins:     null(),
    processModelNames: {}
  )
)
```

## Condizione Gateway XOR

**Percorso "Sì"** (processi bloccati trovati):
```
pv!stuckResult.hasStuck
```

**Percorso "No"** (default):
```
not(pv!stuckResult.hasStuck)
```

## Codice Script Task 2 — "Prepara corpo email"

```
a!localVariables(
  local!stuck:     index(pv!stuckResult, "stuckList", {}),
  local!count:     index(pv!stuckResult, "stuckCount", 0),
  local!threshold: cons!AON_PERF_STUCK_THRESHOLD_MINS,

  local!lines: a!forEach(
    items: local!stuck,
    expression:
      "• " & index($item, "processModelName", "") &
      " [" & index($item, "processName", "") & "]" &
      " — avviato il " &
      text(index($item, "startTime", null()), "dd/MM/yyyy HH:mm") &
      " — attivo da " &
      rule!AON_PERF_formatDuration(seconds: index($item,"runningMins",0) * 60) &
      " (da: " & index($item, "initiator", "N/D") & ")"
  ),

  a!save(
    pv!alertBody,
    "ALERT — Processi Bloccati in Hygieia" & char(10) &
    "Rilevamento: " & text(now(), "dd/MM/yyyy HH:mm:ss") & char(10) &
    char(10) &
    local!count & " processo/i attivo/i da più di " &
    local!threshold & " minuti:" & char(10) & char(10) &
    joinarray(local!lines, char(10)) &
    char(10) & char(10) &
    "Verificare immediatamente in Appian Process Monitor."
  )
)
```

## Parametri Call Activity → AON_PERF_SendAlert

| Parametro      | Valore                                                              |
|----------------|---------------------------------------------------------------------|
| `alertSubject` | `"ALERT Hygieia — " & pv!stuckResult.stuckCount & " proc. bloccati"` |
| `alertBody`    | `pv!alertBody`                                                      |
| `recipients`   | `cons!AON_PERF_ALERT_RECIPIENTS`                                    |

## Permessi richiesti

Il Service Account associato al PM deve avere:
- Accesso in lettura al Process Analytics Report (`AON_PERF_PAR_EXECUTION_TIMES`)
- Permesso di avvio processi (per eseguire il sub-processo `AON_PERF_SendAlert`)
- Permesso di invio email (configurato in Admin Console → Email)
