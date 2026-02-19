/* ============================================================
 * AON_PERF_Dashboard
 *
 * Dashboard principale di monitoraggio delle performance.
 * Da incollare nel campo "Form Expression" di una nuova Interface
 * creata in Appian Designer.
 *
 * SEZIONI:
 *   1. Filtri       — periodo, modelli, finestra real-time, refresh
 *   2. Alert Banner — processi bloccati (visibile solo se hasStuck)
 *   3. KPI Cards    — totale esecuzioni, avg, p95, attivi ora, errori
 *   4. Trend Chart  — grafico a linee giornaliero (asse Y = secondi)
 *   5. Grid dettaglio — per modello: avg, mediana, p95, min, max, error%
 *   6. Real-time    — ultimi N min: attivi / completati / errori
 * ============================================================ */
a!localVariables(

  /* ---- Stato filtri (modificabili dall'utente) ---- */
  local!trendDays:      cons!AON_PERF_DEFAULT_TREND_DAYS,
  local!selectedModels: {},
  local!instantMins:    5,
  local!refreshTs:      now(),

  /* ---- Caricamento dati con refresh on demand ---- */
  local!metrics: a!refreshVariable(
    value: rule!AON_PERF_getProcessMetrics(
      startDate:         today() - local!trendDays,
      endDate:           today(),
      processModelNames: local!selectedModels
    ),
    refreshOnVarChange: local!refreshTs
  ),

  local!trend: a!refreshVariable(
    value: rule!AON_PERF_getDailyTrend(
      days:              local!trendDays,
      processModelNames: local!selectedModels
    ),
    refreshOnVarChange: local!refreshTs
  ),

  local!instant: a!refreshVariable(
    value: rule!AON_PERF_getInstantMetrics(
      minutes:           local!instantMins,
      processModelNames: local!selectedModels
    ),
    refreshOnVarChange: local!refreshTs
  ),

  local!stuckCheck: a!refreshVariable(
    value: rule!AON_PERF_checkStuckProcesses(
      thresholdMins:     null(),
      processModelNames: {}
    ),
    refreshOnVarChange: local!refreshTs
  ),

  /* ---- Shortcuts ---- */
  local!summary:   index(local!metrics,    "summary",   { count:0, avgSec:0, medianSec:0, p95Sec:0, minSec:0, maxSec:0 }),
  local!byProcess: index(local!metrics,    "byProcess", {}),
  local!stuckList: index(local!stuckCheck, "stuckList", {}),
  local!hasStuck:  index(local!stuckCheck, "hasStuck",  false()),

  /* ============================================================
   *  LAYOUT
   * ============================================================ */
  a!formLayout(
    label:     "Performance Monitoring — Hygieia",
    labelSize: "LARGE",
    contents: {

      /* ---- 1. FILTRI ---- */
      a!sectionLayout(
        label:     "Filtri",
        labelSize: "SMALL",
        contents: {
          a!columnsLayout(
            columns: {
              a!columnLayout(
                width: "MEDIUM",
                contents: {
                  a!dropdownField(
                    label:        "Periodo di analisi",
                    choiceLabels: {"7 giorni","15 giorni","30 giorni","60 giorni","90 giorni"},
                    choiceValues: {7, 15, 30, 60, 90},
                    value:        local!trendDays,
                    saveInto:     local!trendDays
                  )
                }
              ),
              a!columnLayout(
                width: "WIDE",
                contents: {
                  a!multipleDropdownField(
                    label:        "Modelli di processo",
                    placeholder:  "Tutti i modelli...",
                    choiceLabels: index(local!byProcess, "processModelName", {}),
                    choiceValues: index(local!byProcess, "processModelName", {}),
                    value:        local!selectedModels,
                    saveInto:     local!selectedModels
                  )
                }
              ),
              a!columnLayout(
                width: "NARROW",
                contents: {
                  a!dropdownField(
                    label:        "Finestra real-time",
                    choiceLabels: {"1 min","5 min","15 min","30 min"},
                    choiceValues: {1, 5, 15, 30},
                    value:        local!instantMins,
                    saveInto:     local!instantMins
                  )
                }
              ),
              a!columnLayout(
                width: "NARROW",
                contents: {
                  a!buttonArrayLayout(
                    buttons: {
                      a!buttonWidget(
                        label:   "Aggiorna",
                        icon:    "refresh",
                        style:   "PRIMARY",
                        saveInto: a!save(local!refreshTs, now())
                      )
                    }
                  )
                }
              )
            }
          )
        }
      ),

      /* ---- 2. ALERT BANNER processi bloccati ---- */
      a!sectionLayout(
        showWhen:   local!hasStuck,
        label:      "Processi Bloccati — Attenzione",
        labelSize:  "MEDIUM",
        labelColor: "NEGATIVE",
        contents: {
          a!richTextDisplayField(
            value: a!richTextItem(
              text: length(local!stuckList) & " processo/i attivo/i da più di " &
                    cons!AON_PERF_STUCK_THRESHOLD_MINS & " minuti.",
              color: "NEGATIVE",
              style: "STRONG"
            )
          ),
          a!gridField(
            data: local!stuckList,
            columns: {
              a!gridColumn(label: "Modello",        value: index(fv!row, "processModelName", "")),
              a!gridColumn(label: "Istanza",         value: index(fv!row, "processName", "")),
              a!gridColumn(label: "Avviato il",      value: text(index(fv!row, "startTime", null()), "dd/MM/yyyy HH:mm")),
              a!gridColumn(
                label: "In esecuzione da",
                align: "CENTER",
                value: rule!AON_PERF_formatDuration(
                  seconds: index(fv!row, "runningMins", 0) * 60
                )
              ),
              a!gridColumn(label: "Avviato da", value: index(fv!row, "initiator", ""))
            },
            rowHeader: 1
          )
        }
      ),

      /* ---- 3. KPI CARDS ---- */
      a!sectionLayout(
        label:     "Riepilogo — ultimi " & local!trendDays & " giorni",
        labelSize: "MEDIUM",
        contents: {
          a!columnsLayout(
            columns: {
              /* Totale esecuzioni */
              a!columnLayout(contents: {
                a!cardLayout(contents: {
                  a!richTextDisplayField(
                    align: "CENTER",
                    value: {
                      a!richTextItem(text: index(local!summary,"count",0), size: "LARGE", style: "STRONG"),
                      char(10),
                      a!richTextItem(text: "Esecuzioni totali", size: "SMALL", color: "SECONDARY")
                    }
                  )
                })
              }),
              /* Tempo medio */
              a!columnLayout(contents: {
                a!cardLayout(contents: {
                  a!richTextDisplayField(
                    align: "CENTER",
                    value: {
                      a!richTextItem(
                        text: rule!AON_PERF_formatDuration(seconds: index(local!summary,"avgSec",0)),
                        size: "LARGE", style: "STRONG"
                      ),
                      char(10),
                      a!richTextItem(text: "Tempo medio", size: "SMALL", color: "SECONDARY")
                    }
                  )
                })
              }),
              /* p95 */
              a!columnLayout(contents: {
                a!cardLayout(contents: {
                  a!richTextDisplayField(
                    align: "CENTER",
                    value: {
                      a!richTextItem(
                        text: rule!AON_PERF_formatDuration(seconds: index(local!summary,"p95Sec",0)),
                        size: "LARGE", style: "STRONG",
                        color: if(index(local!summary,"p95Sec",0) > 300, "NEGATIVE", "STANDARD")
                      ),
                      char(10),
                      a!richTextItem(text: "Percentile 95°", size: "SMALL", color: "SECONDARY")
                    }
                  )
                })
              }),
              /* Attivi ora */
              a!columnLayout(contents: {
                a!cardLayout(contents: {
                  a!richTextDisplayField(
                    align: "CENTER",
                    value: {
                      a!richTextItem(
                        text: index(local!instant,"activeCount",0),
                        size: "LARGE", style: "STRONG",
                        color: if(index(local!instant,"activeCount",0) > 50, "WARN", "POSITIVE")
                      ),
                      char(10),
                      a!richTextItem(
                        text: "Attivi ora (ult. " & local!instantMins & " min)",
                        size: "SMALL", color: "SECONDARY"
                      )
                    }
                  )
                })
              }),
              /* Errori */
              a!columnLayout(contents: {
                a!cardLayout(contents: {
                  a!richTextDisplayField(
                    align: "CENTER",
                    value: {
                      a!richTextItem(
                        text: index(local!instant,"errorCount",0),
                        size: "LARGE", style: "STRONG",
                        color: if(index(local!instant,"errorCount",0) > 0, "NEGATIVE", "POSITIVE")
                      ),
                      char(10),
                      a!richTextItem(
                        text: "Errori (ult. " & local!instantMins & " min)",
                        size: "SMALL", color: "SECONDARY"
                      )
                    }
                  )
                })
              })
            }
          )
        }
      ),

      /* ---- 4. GRAFICO TREND GIORNALIERO ---- */
      a!sectionLayout(
        label:     "Trend giornaliero — tempo medio di esecuzione (secondi)",
        labelSize: "MEDIUM",
        contents: {
          a!lineChartField(
            labelPosition:  "COLLAPSED",
            categories:     index(local!trend, "dates", {}),
            series: a!forEach(
              items: index(local!trend, "series", {}),
              expression: a!chartSeries(
                label: index($item, "processModelName", ""),
                data:  index($item, "dailyAvgSec",      {})
              )
            ),
            xAxisTitle:     "Giorno",
            yAxisTitle:     "Secondi (media)",
            showLegend:     true(),
            showDataLabels: false(),
            height:         "MEDIUM"
          )
        }
      ),

      /* ---- 5. DETTAGLIO PER MODELLO ---- */
      a!sectionLayout(
        label:     "Dettaglio per modello di processo",
        labelSize: "MEDIUM",
        contents: {
          a!gridField(
            labelPosition: "COLLAPSED",
            data: a!dataSubset(
              data:      local!byProcess,
              startIndex: 1,
              batchSize:  50,
              sort: { a!sortInfo(field: "avgSec", ascending: false()) }
            ),
            columns: {
              a!gridColumn(label: "Modello",        width: "WIDE",   value: index(fv!row,"processModelName","")),
              a!gridColumn(label: "# Esecuzioni",   align: "CENTER", value: index(fv!row,"count",0)),
              a!gridColumn(label: "Tempo Medio",    align: "CENTER", value: rule!AON_PERF_formatDuration(seconds: index(fv!row,"avgSec",0))),
              a!gridColumn(label: "Mediana",        align: "CENTER", value: rule!AON_PERF_formatDuration(seconds: index(fv!row,"medianSec",0))),
              a!gridColumn(label: "Percentile 95°", align: "CENTER", value: rule!AON_PERF_formatDuration(seconds: index(fv!row,"p95Sec",0))),
              a!gridColumn(label: "Min",            align: "CENTER", value: rule!AON_PERF_formatDuration(seconds: index(fv!row,"minSec",0))),
              a!gridColumn(label: "Max",            align: "CENTER", value: rule!AON_PERF_formatDuration(seconds: index(fv!row,"maxSec",0))),
              a!gridColumn(label: "% Errori",       align: "CENTER", value: index(fv!row,"errorRate",0) & "%")
            },
            rowHeader:  1,
            pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 25)
          )
        }
      ),

      /* ---- 6. REAL-TIME ---- */
      a!sectionLayout(
        label:     "Stato in tempo reale — ultimi " & local!instantMins & " minuti",
        labelSize: "MEDIUM",
        contents: {
          a!columnsLayout(
            columns: {
              a!columnLayout(
                width: "WIDE",
                contents: {
                  a!gridField(
                    labelPosition: "COLLAPSED",
                    data: index(local!instant, "byProcess", {}),
                    columns: {
                      a!gridColumn(label: "Processo",    width: "WIDE",   value: index(fv!row,"processModelName","")),
                      a!gridColumn(label: "Attivi",      align: "CENTER", value: index(fv!row,"activeCount",0)),
                      a!gridColumn(label: "Completati",  align: "CENTER", value: index(fv!row,"completedCount",0)),
                      a!gridColumn(label: "Errori",      align: "CENTER", value: index(fv!row,"errorCount",0)),
                      a!gridColumn(label: "T. Medio",    align: "CENTER",
                        value: rule!AON_PERF_formatDuration(seconds: index(fv!row,"avgSec",null()))
                      )
                    },
                    rowHeader: 1,
                    showWhen: length(index(local!instant,"byProcess",{})) > 0
                  ),
                  a!richTextDisplayField(
                    showWhen: length(index(local!instant,"byProcess",{})) = 0,
                    value: a!richTextItem(
                      text: "Nessuna esecuzione negli ultimi " & local!instantMins & " minuti.",
                      color: "SECONDARY"
                    )
                  )
                }
              ),
              a!columnLayout(
                width: "NARROW",
                contents: {
                  a!richTextDisplayField(
                    value: {
                      a!richTextItem(text: "Completati: ", style: "STRONG"),
                      a!richTextItem(text: index(local!instant,"completedCount",0), color: "POSITIVE"),
                      char(10),
                      a!richTextItem(text: "Attivi:     ", style: "STRONG"),
                      a!richTextItem(text: index(local!instant,"activeCount",0)),
                      char(10),
                      a!richTextItem(text: "Errori:     ", style: "STRONG"),
                      a!richTextItem(
                        text: index(local!instant,"errorCount",0),
                        color: if(index(local!instant,"errorCount",0) > 0, "NEGATIVE", "STANDARD")
                      ),
                      char(10), char(10),
                      a!richTextItem(
                        text: "Agg. " & text(index(local!instant,"lastUpdated",now()), "HH:mm:ss"),
                        size: "SMALL", color: "SECONDARY"
                      )
                    }
                  )
                }
              )
            }
          )
        }
      )

    },
    buttons: a!buttonLayout(
      primaryButtons: {
        a!buttonWidget(
          label:   "Esporta Report",
          icon:    "download",
          style:   "SECONDARY",
          saveInto: {}
        )
      }
    )
  )
)
