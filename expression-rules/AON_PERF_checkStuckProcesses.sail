/* ============================================================
 * AON_PERF_checkStuckProcesses
 *
 * Identifica i processi ACTIVE bloccati da più di N minuti.
 * Chiamata dal monitor schedulato e usata dal banner alert
 * della dashboard.
 *
 * INPUT:
 *   ri!thresholdMins      (Integer)      — default: AON_PERF_STUCK_THRESHOLD_MINS
 *   ri!processModelNames  (List of Text) — default: AON_PERF_MONITORED_PROCESS_MODELS
 *
 * OUTPUT: Dictionary {
 *   hasStuck   : Boolean
 *   stuckCount : Integer
 *   stuckList  : List of { processName, processModelName,
 *                           startTime, runningMins, initiator }
 *   checkedAt  : DateTime
 * }
 * ============================================================ */
a!localVariables(
  local!threshold: if(
    isnull(ri!thresholdMins),
    cons!AON_PERF_STUCK_THRESHOLD_MINS,
    ri!thresholdMins
  ),

  local!monitoredModels: if(
    not(isnull(ri!processModelNames)) & length(ri!processModelNames) > 0,
    ri!processModelNames,
    fromjson(cons!AON_PERF_MONITORED_PROCESS_MODELS)
  ),

  /* Soglia: processi avviati PRIMA di questo timestamp */
  local!cutoffTime: now() - (local!threshold / 1440),

  local!queryResult: a!queryProcessAnalytics(
    processAnalyticsReport: a!processAnalyticsReportById(
      id: cons!AON_PERF_PAR_EXECUTION_TIMES
    ),
    query: a!query(
      selection: a!querySelection(
        columns: {
          a!queryColumn(field: "c1"),   /* processName      */
          a!queryColumn(field: "c2"),   /* processModelName */
          a!queryColumn(field: "c3"),   /* startTime        */
          a!queryColumn(field: "c7")    /* initiator        */
        }
      ),
      filter: a!queryLogicalExpression(
        operator: "AND",
        filters: {
          /* Solo processi ancora attivi */
          a!queryFilter(field: "c6", operator: "=",  value: "ACTIVE"),
          /* Avviati prima della soglia */
          a!queryFilter(field: "c3", operator: "<=", value: local!cutoffTime),
          /* Solo i processi critici configurati */
          if(
            length(local!monitoredModels) > 0,
            a!queryFilter(field: "c2", operator: "in", value: local!monitoredModels),
            {}
          )
        }
      ),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500)
    )
  ),

  local!rows: index(local!queryResult, "data", {}),

  local!stuckList: a!forEach(
    items: local!rows,
    expression: a!localVariables(
      local!start: index($item, "c3", null()),
      local!runningMins: if(
        isnull(local!start),
        null(),
        round(
          (dateTimeToMilliseconds(now()) - dateTimeToMilliseconds(local!start)) / 60000,
          0
        )
      ),
      {
        processName:      index($item, "c1", ""),
        processModelName: index($item, "c2", ""),
        startTime:        local!start,
        runningMins:      local!runningMins,
        initiator:        index($item, "c7", "")
      }
    )
  ),

  /* --- Output --- */
  {
    hasStuck:   length(local!stuckList) > 0,
    stuckCount: length(local!stuckList),
    stuckList:  local!stuckList,
    checkedAt:  now()
  }
)
