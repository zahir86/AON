/* ============================================================
 * AON_PERF_getDailyTrend
 *
 * Calcola il trend giornaliero dei tempi medi di esecuzione.
 * Output formattato per un a!lineChartField().
 *
 * INPUT:
 *   ri!days               (Integer)      — default: AON_PERF_DEFAULT_TREND_DAYS
 *   ri!processModelNames  (List of Text) — filtro; vuoto = tutti
 *
 * OUTPUT: Dictionary {
 *   dates     : List of Text   — etichette asse X ("dd/MM")
 *   series    : List of {
 *                 processModelName : Text,
 *                 dailyAvgSec      : List of Number(Decimal)  — null se nessuna esecuzione
 *               }
 *   globalAvg : List of Number(Decimal)  — media giornaliera tutti i processi
 * }
 * ============================================================ */
a!localVariables(
  local!days:      if(isnull(ri!days), cons!AON_PERF_DEFAULT_TREND_DAYS, ri!days),
  local!startDate: today() - local!days,

  /* Recupera dati grezzi */
  local!metrics: rule!AON_PERF_getProcessMetrics(
    startDate:         local!startDate,
    endDate:           today(),
    processModelNames: ri!processModelNames
  ),
  local!rows: index(local!metrics, "rawData", {}),

  /* Sequenza di date (asse X) */
  local!dateRange: a!forEach(
    items:      enumerate(local!days + 1),
    expression: local!startDate + $item
  ),
  local!dateLabels: a!forEach(
    items:      local!dateRange,
    expression: text($item, "dd/MM")
  ),

  /* Funzione helper: data pura da un DateTime */
  /* Raggruppa le esecuzioni per giorno */
  local!rowsByDay: a!forEach(
    items: local!dateRange,
    expression: a!localVariables(
      local!d: $item,
      filter(
        lambda!r(
          not(isnull(index(r, "startTime", null()))) &
          date(
            year(index(r, "startTime", null())),
            month(index(r, "startTime", null())),
            day(index(r, "startTime", null()))
          ) = local!d
        ),
        local!rows
      )
    )
  ),

  /* Serie per modello di processo */
  local!models: toSet(
    filter(lambda!v(not(isnull(v))), index(local!rows, "processModelName", {}))
  ),

  local!series: a!forEach(
    items: local!models,
    expression: a!localVariables(
      local!pm: $item,
      {
        processModelName: local!pm,
        dailyAvgSec: a!forEach(
          items: local!rowsByDay,
          expression: a!localVariables(
            local!dayPmRows: filter(
              lambda!r(index(r, "processModelName", "") = local!pm),
              $item
            ),
            local!times: filter(
              lambda!v(not(isnull(v))),
              index(local!dayPmRows, "elapsedSec", {})
            ),
            if(length(local!times) = 0, null(), round(average(local!times), 1))
          )
        )
      }
    )
  ),

  /* Media globale giornaliera */
  local!globalAvg: a!forEach(
    items: local!rowsByDay,
    expression: a!localVariables(
      local!times: filter(
        lambda!v(not(isnull(v))),
        index($item, "elapsedSec", {})
      ),
      if(length(local!times) = 0, null(), round(average(local!times), 1))
    )
  ),

  /* --- Output --- */
  {
    dates:     local!dateLabels,
    series:    local!series,
    globalAvg: local!globalAvg
  }
)
