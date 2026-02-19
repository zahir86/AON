/* ============================================================
 * AON_PERF_getInstantMetrics
 *
 * Metriche istantanee della finestra scorrevole degli ultimi N minuti.
 * Usato dal pannello "Stato in tempo reale" della dashboard.
 *
 * INPUT:
 *   ri!minutes            (Integer)      — finestra in minuti (default: 5)
 *   ri!processModelNames  (List of Text) — filtro; vuoto = tutti
 *
 * OUTPUT: Dictionary {
 *   windowMins     : Integer
 *   activeCount    : Integer
 *   completedCount : Integer
 *   errorCount     : Integer
 *   avgSec         : Number(Decimal) | null
 *   byProcess      : List of { processModelName, activeCount,
 *                               completedCount, errorCount, avgSec }
 *   lastUpdated    : DateTime
 * }
 * ============================================================ */
a!localVariables(
  local!mins:   if(isnull(ri!minutes), 5, ri!minutes),
  /* now() è in giorni frazionari; divido per minuti nel giorno */
  local!cutoff: now() - (local!mins / 1440),

  local!queryResult: a!queryProcessAnalytics(
    processAnalyticsReport: a!processAnalyticsReportById(
      id: cons!AON_PERF_PAR_EXECUTION_TIMES
    ),
    query: a!query(
      selection: a!querySelection(
        columns: {
          a!queryColumn(field: "c1"),
          a!queryColumn(field: "c2"),
          a!queryColumn(field: "c3"),
          a!queryColumn(field: "c4"),
          a!queryColumn(field: "c5"),
          a!queryColumn(field: "c6")
        }
      ),
      filter: a!queryLogicalExpression(
        operator: "AND",
        filters: {
          a!queryFilter(field: "c3", operator: ">=", value: local!cutoff),
          if(
            not(isnull(ri!processModelNames)) & length(ri!processModelNames) > 0,
            a!queryFilter(field: "c2", operator: "in", value: ri!processModelNames),
            {}
          )
        }
      ),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1000)
    )
  ),

  local!rows: index(local!queryResult, "data", {}),

  local!activeRows:    filter(lambda!r(index(r,"c6","") = "ACTIVE"),    local!rows),
  local!completedRows: filter(lambda!r(index(r,"c6","") = "COMPLETED"), local!rows),
  local!errorRows:     filter(lambda!r(index(r,"c6","") = "ERROR"),     local!rows),

  local!completedTimes: filter(
    lambda!v(not(isnull(v))),
    index(local!completedRows, "c5", {})
  ),

  local!models: toSet(
    filter(lambda!v(not(isnull(v))), index(local!rows, "c2", {}))
  ),

  local!byProcess: a!forEach(
    items: local!models,
    expression: a!localVariables(
      local!pm: $item,
      local!pmActive:    filter(lambda!r(index(r,"c2","")=local!pm & index(r,"c6","")="ACTIVE"),    local!rows),
      local!pmCompleted: filter(lambda!r(index(r,"c2","")=local!pm & index(r,"c6","")="COMPLETED"), local!rows),
      local!pmErrors:    filter(lambda!r(index(r,"c2","")=local!pm & index(r,"c6","")="ERROR"),     local!rows),
      local!pmTimes:     filter(lambda!v(not(isnull(v))), index(local!pmCompleted,"c5",{})),
      {
        processModelName: local!pm,
        activeCount:      length(local!pmActive),
        completedCount:   length(local!pmCompleted),
        errorCount:       length(local!pmErrors),
        avgSec: if(length(local!pmTimes)=0, null(), round(average(local!pmTimes),1))
      }
    )
  ),

  /* --- Output --- */
  {
    windowMins:     local!mins,
    activeCount:    length(local!activeRows),
    completedCount: length(local!completedRows),
    errorCount:     length(local!errorRows),
    avgSec: if(
      length(local!completedTimes) = 0, null(),
      round(average(local!completedTimes), 1)
    ),
    byProcess:   local!byProcess,
    lastUpdated: now()
  }
)
