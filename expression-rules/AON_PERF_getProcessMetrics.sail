/* ============================================================
 * AON_PERF_getProcessMetrics
 *
 * Interroga il Process Analytics Report configurato e restituisce
 * statistiche aggregate per modello di processo.
 *
 * PREREQUISITO: Costante AON_PERF_PAR_EXECUTION_TIMES valorizzata
 *               con l'UUID del PAR (vedi docs/setup-guide.md §1).
 *
 * INPUT:
 *   ri!startDate          (Date)              — default: oggi - AON_PERF_DEFAULT_TREND_DAYS
 *   ri!endDate            (Date)              — default: oggi
 *   ri!processModelNames  (List of Text)      — filtro; vuoto = tutti i processi
 *
 * OUTPUT: Dictionary {
 *   summary   : { count, avgSec, medianSec, p95Sec, minSec, maxSec }
 *   byProcess : List of { processModelName, count, avgSec, medianSec,
 *                         p95Sec, minSec, maxSec, errorRate }
 *   rawData   : List of { processName, processModelName, startTime,
 *                         completionTime, elapsedSec, status, initiator }
 * }
 *
 * COLONNE PAR (in ordine):
 *   c1 = Process Name       c5 = Elapsed Time (sec)
 *   c2 = Process Model Name c6 = Status
 *   c3 = Start Time         c7 = Initiator
 *   c4 = Completion Time
 * ============================================================ */
a!localVariables(
  local!start: if(isnull(ri!startDate),
    today() - cons!AON_PERF_DEFAULT_TREND_DAYS,
    ri!startDate
  ),
  local!end: if(isnull(ri!endDate), today(), ri!endDate),

  /* --- Query al Process Analytics Report --- */
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
          a!queryColumn(field: "c6"),
          a!queryColumn(field: "c7")
        }
      ),
      filter: a!queryLogicalExpression(
        operator: "AND",
        filters: {
          a!queryFilter(field: "c3", operator: ">=", value: local!start),
          a!queryFilter(field: "c3", operator: "<=", value: local!end + 1),
          if(
            not(isnull(ri!processModelNames)) & length(ri!processModelNames) > 0,
            a!queryFilter(field: "c2", operator: "in", value: ri!processModelNames),
            {}
          )
        }
      ),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5000)
    )
  ),

  local!rows:  index(local!queryResult, "data", {}),
  local!count: length(local!rows),

  /* --- Statistiche globali --- */
  local!allTimes: filter(
    lambda!v(not(isnull(v))),
    index(local!rows, "c5", {})
  ),
  local!sorted:     sort(local!allTimes, true()),
  local!validCount: length(local!sorted),

  local!summary: if(
    local!validCount = 0,
    { count: 0, avgSec: 0, medianSec: 0, p95Sec: 0, minSec: 0, maxSec: 0 },
    {
      count:     local!count,
      avgSec:    round(average(local!sorted), 1),
      medianSec: local!sorted[max(1, round(local!validCount * 0.50, 0))],
      p95Sec:    local!sorted[max(1, round(local!validCount * 0.95, 0))],
      minSec:    local!sorted[1],
      maxSec:    local!sorted[local!validCount]
    }
  ),

  /* --- Statistiche per singolo modello --- */
  local!uniqueModels: toSet(
    filter(lambda!v(not(isnull(v))), index(local!rows, "c2", {}))
  ),

  local!byProcess: a!forEach(
    items: local!uniqueModels,
    expression: a!localVariables(
      local!pmRows:  filter(lambda!r(index(r,"c2","") = $item), local!rows),
      local!pmTimes: filter(lambda!v(not(isnull(v))), index(local!pmRows,"c5",{})),
      local!pmSort:  sort(local!pmTimes, true()),
      local!pmN:     length(local!pmSort),
      local!errN:    length(filter(lambda!r(index(r,"c6","") = "ERROR"), local!pmRows)),
      {
        processModelName: $item,
        count:     length(local!pmRows),
        avgSec:    if(local!pmN = 0, 0, round(average(local!pmSort), 1)),
        medianSec: if(local!pmN = 0, 0, local!pmSort[max(1, round(local!pmN*0.50,0))]),
        p95Sec:    if(local!pmN = 0, 0, local!pmSort[max(1, round(local!pmN*0.95,0))]),
        minSec:    if(local!pmN = 0, 0, local!pmSort[1]),
        maxSec:    if(local!pmN = 0, 0, local!pmSort[local!pmN]),
        errorRate: if(length(local!pmRows) = 0, 0,
                     round(local!errN * 100 / length(local!pmRows), 1))
      }
    )
  ),

  /* --- Output --- */
  {
    summary:   local!summary,
    byProcess: local!byProcess,
    rawData: a!forEach(
      items: local!rows,
      expression: {
        processName:      index($item, "c1", ""),
        processModelName: index($item, "c2", ""),
        startTime:        index($item, "c3", null()),
        completionTime:   index($item, "c4", null()),
        elapsedSec:       index($item, "c5", null()),
        status:           index($item, "c6", ""),
        initiator:        index($item, "c7", "")
      }
    )
  }
)
