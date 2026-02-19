# AON_PERF_SendAlert — Process Model (Sub-processo)

Sub-processo riutilizzabile per l'invio di notifiche email di alert.
Chiamato da `AON_PERF_ScheduledMonitor` (e da qualsiasi altro PM).

## Flusso

```
[Start — Subprocess]
        │
        ▼
[Script Task: Invia Email]
        │
        ▼
[End Event]
```

## Parametri di input (Process Parameters)

| Parametro        | Tipo | Descrizione                       |
|------------------|------|-----------------------------------|
| `pp!alertSubject` | Text | Oggetto dell'email                |
| `pp!alertBody`    | Text | Corpo in testo semplice           |
| `pp!recipients`   | Text | Destinatari separati da `;`       |

## Codice Script Task — "Invia Email"

```
a!localVariables(
  local!recipientList: a!forEach(
    items:      split(pp!recipients, ";"),
    expression: trim($item)
  ),

  a!sendEmail(
    to:      local!recipientList,
    subject: pp!alertSubject,
    body:    pp!alertBody
  )
)
```

## Note

- Appian richiede che `a!sendEmail` sia usato all'interno di un **Script Task** (non in una Expression Rule)
- Per abilitare l'invio email verificare in **Admin Console → Email** che il server SMTP sia configurato
- Per aggiungere un log audit degli alert inviati, creare un'entità `AON_PERF_AlertLog` e scrivere i dati dopo `a!sendEmail` tramite `a!writeToDataStore`
