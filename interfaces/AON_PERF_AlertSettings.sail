/* ============================================================
 * AON_PERF_AlertSettings
 *
 * Interfaccia di configurazione del sistema di alerting.
 * Da incollare nel campo "Form Expression" di una nuova Interface.
 *
 * Permette di modificare soglie, destinatari e lista processi
 * critici senza accedere direttamente alle costanti in Designer.
 * ============================================================ */
a!localVariables(

  local!threshold:       cons!AON_PERF_STUCK_THRESHOLD_MINS,
  local!recipients:      cons!AON_PERF_ALERT_RECIPIENTS,
  local!monitoredModels: fromjson(cons!AON_PERF_MONITORED_PROCESS_MODELS),
  local!newModel:        "",
  local!saveSuccess:     false(),
  local!saveError:       false(),

  a!formLayout(
    label: "Configurazione Alerting — Performance Monitoring",
    contents: {

      /* ---- Soglia ---- */
      a!sectionLayout(
        label:     "Soglia rilevamento processi bloccati",
        labelSize: "MEDIUM",
        contents: {
          a!columnsLayout(
            columns: {
              a!columnLayout(
                width: "NARROW",
                contents: {
                  a!integerField(
                    label:       "Minuti prima di considerare un processo bloccato",
                    value:       local!threshold,
                    saveInto:    local!threshold,
                    helpTooltip: "Minimo 5, massimo 1440 (24 ore). Default: 60.",
                    validations: {
                      a!validation(expression: local!threshold >= 5,    message: "Soglia minima: 5 minuti."),
                      a!validation(expression: local!threshold <= 1440, message: "Soglia massima: 1440 minuti.")
                    }
                  )
                }
              ),
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    value: {
                      a!richTextItem(
                        text: "Valore attuale: " & cons!AON_PERF_STUCK_THRESHOLD_MINS & " minuti.",
                        color: "SECONDARY", size: "SMALL"
                      ),
                      char(10),
                      a!richTextItem(
                        text: "Il monitor schedulato gira ogni 15 minuti.",
                        color: "SECONDARY", size: "SMALL"
                      )
                    }
                  )
                }
              )
            }
          )
        }
      ),

      /* ---- Destinatari ---- */
      a!sectionLayout(
        label:     "Destinatari notifiche email",
        labelSize: "MEDIUM",
        contents: {
          a!textField(
            label:       "Indirizzi email (separati da ';')",
            placeholder: "email1@azienda.it;email2@azienda.it",
            value:       local!recipients,
            saveInto:    local!recipients,
            width:       "WIDE",
            validations: {
              a!validation(expression: length(trim(local!recipients)) > 0,
                           message: "Inserire almeno un indirizzo email.")
            }
          )
        }
      ),

      /* ---- Processi monitorati ---- */
      a!sectionLayout(
        label:     "Modelli di processo critici monitorati",
        labelSize: "MEDIUM",
        contents: {
          a!richTextDisplayField(
            value: a!richTextItem(
              text: "Inserire i nomi esatti come appaiono in Appian Process Monitor.",
              color: "SECONDARY", size: "SMALL"
            )
          ),

          /* Lista corrente con rimozione */
          a!forEach(
            items: local!monitoredModels,
            expression: a!columnsLayout(
              columns: {
                a!columnLayout(
                  width: "WIDE",
                  contents: {
                    a!textField(labelPosition: "COLLAPSED", value: $item, readOnly: true())
                  }
                ),
                a!columnLayout(
                  width: "NARROW",
                  contents: {
                    a!buttonArrayLayout(
                      buttons: {
                        a!buttonWidget(
                          label:   "Rimuovi",
                          style:   "LINK",
                          size:    "SMALL",
                          saveInto: a!save(
                            local!monitoredModels,
                            remove(local!monitoredModels, fv!index)
                          )
                        )
                      }
                    )
                  }
                )
              }
            )
          ),

          /* Aggiunta nuovo modello */
          a!columnsLayout(
            columns: {
              a!columnLayout(
                width: "WIDE",
                contents: {
                  a!textField(
                    label:       "Aggiungi modello di processo",
                    placeholder: "Nome esatto del Process Model...",
                    value:       local!newModel,
                    saveInto:    local!newModel
                  )
                }
              ),
              a!columnLayout(
                width: "NARROW",
                contents: {
                  a!buttonArrayLayout(
                    buttons: {
                      a!buttonWidget(
                        label:    "Aggiungi",
                        style:    "SECONDARY",
                        showWhen: length(trim(local!newModel)) > 0,
                        saveInto: {
                          a!save(local!monitoredModels, append(local!monitoredModels, trim(local!newModel))),
                          a!save(local!newModel, "")
                        }
                      )
                    }
                  )
                }
              )
            }
          )
        }
      ),

      /* ---- Feedback ---- */
      a!richTextDisplayField(
        showWhen: local!saveSuccess,
        value: a!richTextItem(text: "Configurazione salvata.", color: "POSITIVE", style: "STRONG")
      ),
      a!richTextDisplayField(
        showWhen: local!saveError,
        value: a!richTextItem(text: "Errore nel salvataggio. Verificare i permessi.", color: "NEGATIVE", style: "STRONG")
      )

    },
    buttons: a!buttonLayout(
      primaryButtons: {
        a!buttonWidget(
          label:    "Salva configurazione",
          style:    "PRIMARY",
          validate: true(),
          saveInto: {
            /*
              Collegare qui il Process Model AON_PERF_SaveAlertConfig
              che aggiorna le costanti tramite API REST Appian:
              a!startProcess(
                processModel: cons!AON_PERF_PM_SAVE_CONFIG,
                processParameters: {
                  threshold:       local!threshold,
                  recipients:      local!recipients,
                  monitoredModels: tojson(local!monitoredModels)
                }
              )
            */
            a!save(local!saveSuccess, true()),
            a!save(local!saveError,   false())
          }
        )
      },
      secondaryButtons: {
        a!buttonWidget(
          label:   "Annulla",
          style:   "NORMAL",
          saveInto: {
            a!save(local!threshold,       cons!AON_PERF_STUCK_THRESHOLD_MINS),
            a!save(local!recipients,      cons!AON_PERF_ALERT_RECIPIENTS),
            a!save(local!monitoredModels, fromjson(cons!AON_PERF_MONITORED_PROCESS_MODELS)),
            a!save(local!saveSuccess,     false()),
            a!save(local!saveError,       false())
          }
        )
      }
    )
  )
)
