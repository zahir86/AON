/* ============================================================
 * AON_PERF_formatDuration
 *
 * Converte un numero di secondi in stringa leggibile.
 * Esempi: 3723 → "1h 02m 03s" | 45 → "45s" | 0 → "< 1s"
 *
 * INPUT:
 *   ri!seconds  (Number(Decimal))  — durata in secondi
 *
 * OUTPUT: Text
 * ============================================================ */
if(
  or(isnull(ri!seconds), ri!seconds < 0),
  "N/D",

  a!localVariables(
    local!s:       tointeger(ri!seconds),
    local!hours:   int(local!s / 3600),
    local!minutes: int(mod(local!s, 3600) / 60),
    local!secs:    mod(local!s, 60),

    if(
      local!s = 0,
      "< 1s",
      if(
        local!hours > 0,
        local!hours & "h " & text(local!minutes, "00") & "m " & text(local!secs, "00") & "s",
        if(
          local!minutes > 0,
          local!minutes & "m " & text(local!secs, "00") & "s",
          local!secs & "s"
        )
      )
    )
  )
)
