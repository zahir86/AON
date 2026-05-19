/* ============================================================
 * AON_QUEST_ProcessAssessment
 *
 * Questionario wizard di valutazione processi per analisi di
 * automazione. Da incollare nel campo "Form Expression" di una
 * nuova Interface creata in Appian Designer.
 *
 * SEZIONI:
 *   1. Process Information   — identificazione del processo
 *   2. Strategic Assessment  — allineamento strategico e impatto
 *   3. Process Maturity      — standardizzazione, dati, sistemi
 *   4. Risk & Compliance     — rischio, normativa, supervisione
 *   5. Performance & Adoption — effort manuale, errori, adozione
 * ============================================================ */
a!localVariables(

  /* ---- Navigazione wizard ---- */
  local!currentStep: 1,
  local!totalSteps:  5,
  local!submitted:   false(),

  /* ---- Sezione 1: Process Information ---- */
  local!processName:        "",
  local!processDescription: "",
  local!department:         null(),

  /* ---- Sezione 2: Strategic Assessment ---- */
  local!businessImpact:     null(),
  local!customerImpact:     null(),
  local!processCriticality: null(),
  local!frequency:          null(),

  /* ---- Sezione 3: Process Maturity ---- */
  local!standardization:   null(),
  local!repeatability:     null(),
  local!documentation:     null(),
  local!dataAvailability:  null(),
  local!dataType:          null(),
  local!systemIntegration: null(),

  /* ---- Sezione 4: Risk & Compliance ---- */
  local!regulatoryExposure:  null(),
  local!humanOversight:      null(),
  local!decisionSensitivity: null(),
  local!auditability:        null(),

  /* ---- Sezione 5: Performance & Adoption ---- */
  local!manualEffort:       null(),
  local!errorFrequency:     null(),
  local!processingTime:     null(),
  local!employeeResistance: null(),
  local!trainingNeeds:      null(),

  a!formLayout(
    label:     "Process Automation Assessment",
    labelSize: "LARGE",
    contents: {

      /* ============================================================
       * PROGRESS HEADER
       * ============================================================ */
      a!sectionLayout(
        showWhen:      not(local!submitted),
        labelPosition: "COLLAPSED",
        contents: {
          a!columnsLayout(
            columns: {
              a!columnLayout(
                width: "WIDE",
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: {
                      a!richTextItem(
                        text: "Step " & local!currentStep & " of " & local!totalSteps & " — ",
                        style: "STRONG"
                      ),
                      a!richTextItem(
                        text: choose(
                          local!currentStep,
                          "Process Information",
                          "Strategic Assessment",
                          "Process Maturity",
                          "Risk & Compliance",
                          "Performance & Adoption"
                        ),
                        style: "STRONG",
                        color: "ACCENT"
                      )
                    }
                  )
                }
              ),
              a!columnLayout(
                width: "NARROW",
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    align: "RIGHT",
                    value: a!richTextItem(
                      text: text(((local!currentStep - 1) * 100) / local!totalSteps, "#0") & "% complete",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  )
                }
              )
            }
          ),
          a!columnsLayout(
            columns: a!forEach(
              items: enumerate(local!totalSteps),
              expression: a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "▬▬▬",
                      color: if(fv!index <= local!currentStep, "ACCENT", "SECONDARY"),
                      size:  "LARGE"
                    )
                  )
                }
              )
            )
          )
        }
      ),

      /* ============================================================
       * SEZIONE 1 — Process Information
       * ============================================================ */
      a!sectionLayout(
        showWhen:  local!currentStep = 1,
        label:     "Process Information",
        labelSize: "MEDIUM",
        contents: {
          a!textField(
            label:        "Process Name",
            instructions: "What is the name of the process?",
            value:        local!processName,
            saveInto:     local!processName,
            required:     true(),
            width:        "WIDE"
          ),
          a!paragraphField(
            label:        "Process Description",
            instructions: "Briefly describe the process.",
            value:        local!processDescription,
            saveInto:     local!processDescription,
            required:     true(),
            height:       "SHORT"
          ),
          a!dropdownField(
            label:        "Department / Business Area",
            instructions: "Which business area owns the process?",
            placeholder:  "Select a department...",
            choiceLabels: {"Finance","HR","Operations","Customer Service","IT","Legal","Other"},
            choiceValues: {"Finance","HR","Operations","Customer Service","IT","Legal","Other"},
            value:        local!department,
            saveInto:     local!department,
            required:     true()
          )
        }
      ),

      /* ============================================================
       * SEZIONE 2 — Strategic Assessment
       * ============================================================ */
      a!sectionLayout(
        showWhen:  local!currentStep = 2,
        label:     "Strategic Assessment",
        labelSize: "MEDIUM",
        contents: {
          a!columnsLayout(
            columns: {
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "How important is the process for business operations?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Business Impact",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Low", "Medium", "High"},
                    choiceValues:  {"Low", "Medium", "High"},
                    value:         local!businessImpact,
                    saveInto:      local!businessImpact,
                    required:      true()
                  )
                }
              ),
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "Does the process directly affect customer experience?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Customer Impact",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Yes", "No"},
                    choiceValues:  {"Yes", "No"},
                    value:         local!customerImpact,
                    saveInto:      local!customerImpact,
                    required:      true()
                  )
                }
              ),
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "How critical is the process for organizational performance?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Process Criticality",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Low", "Medium", "High"},
                    choiceValues:  {"Low", "Medium", "High"},
                    value:         local!processCriticality,
                    saveInto:      local!processCriticality,
                    required:      true()
                  )
                }
              ),
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "How frequently is the process executed?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Frequency",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Daily", "Weekly", "Monthly", "Occasionally"},
                    choiceValues:  {"Daily", "Weekly", "Monthly", "Occasionally"},
                    value:         local!frequency,
                    saveInto:      local!frequency,
                    required:      true()
                  )
                }
              )
            }
          )
        }
      ),

      /* ============================================================
       * SEZIONE 3 — Process Maturity
       * ============================================================ */
      a!sectionLayout(
        showWhen:  local!currentStep = 3,
        label:     "Process Maturity",
        labelSize: "MEDIUM",
        contents: {
          a!columnsLayout(
            columns: {
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "Is the process standardized and rule-based?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Standardization",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Low", "Medium", "High"},
                    choiceValues:  {"Low", "Medium", "High"},
                    value:         local!standardization,
                    saveInto:      local!standardization,
                    required:      true()
                  )
                }
              ),
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "Are the activities repetitive?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Repeatability",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Low", "Medium", "High"},
                    choiceValues:  {"Low", "Medium", "High"},
                    value:         local!repeatability,
                    saveInto:      local!repeatability,
                    required:      true()
                  )
                }
              ),
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "Is the process formally documented?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Documentation",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Yes", "Partially", "No"},
                    choiceValues:  {"Yes", "Partially", "No"},
                    value:         local!documentation,
                    saveInto:      local!documentation,
                    required:      true()
                  )
                }
              )
            }
          ),
          a!columnsLayout(
            columns: {
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "Is process data available and accessible?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Data Availability",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Low", "Medium", "High"},
                    choiceValues:  {"Low", "Medium", "High"},
                    value:         local!dataAvailability,
                    saveInto:      local!dataAvailability,
                    required:      true()
                  )
                }
              ),
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "What type of data does the process handle?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Data Type",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Structured", "Unstructured", "Mixed"},
                    choiceValues:  {"Structured", "Unstructured", "Mixed"},
                    value:         local!dataType,
                    saveInto:      local!dataType,
                    required:      true()
                  )
                }
              ),
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "Does the process involve multiple systems?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "System Integration",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Yes", "No"},
                    choiceValues:  {"Yes", "No"},
                    value:         local!systemIntegration,
                    saveInto:      local!systemIntegration,
                    required:      true()
                  )
                }
              )
            }
          )
        }
      ),

      /* ============================================================
       * SEZIONE 4 — Risk & Compliance
       * ============================================================ */
      a!sectionLayout(
        showWhen:  local!currentStep = 4,
        label:     "Risk & Compliance",
        labelSize: "MEDIUM",
        contents: {
          a!columnsLayout(
            columns: {
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "Is the process subject to regulatory or compliance requirements?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Regulatory Exposure",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Low", "Medium", "High"},
                    choiceValues:  {"Low", "Medium", "High"},
                    value:         local!regulatoryExposure,
                    saveInto:      local!regulatoryExposure,
                    required:      true()
                  )
                }
              ),
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "Does the process require human validation or approval?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Human Oversight",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Yes", "No"},
                    choiceValues:  {"Yes", "No"},
                    value:         local!humanOversight,
                    saveInto:      local!humanOversight,
                    required:      true()
                  )
                }
              ),
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "Could automation errors significantly impact customers or operations?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Decision Sensitivity",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Low", "Medium", "High"},
                    choiceValues:  {"Low", "Medium", "High"},
                    value:         local!decisionSensitivity,
                    saveInto:      local!decisionSensitivity,
                    required:      true()
                  )
                }
              ),
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "Is auditability and traceability required?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Auditability",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Yes", "No"},
                    choiceValues:  {"Yes", "No"},
                    value:         local!auditability,
                    saveInto:      local!auditability,
                    required:      true()
                  )
                }
              )
            }
          )
        }
      ),

      /* ============================================================
       * SEZIONE 5 — Performance & Adoption
       * ============================================================ */
      a!sectionLayout(
        showWhen:  local!currentStep = 5,
        label:     "Performance & Adoption",
        labelSize: "MEDIUM",
        contents: {
          a!columnsLayout(
            columns: {
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "How much manual effort is required?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Manual Effort",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Low", "Medium", "High"},
                    choiceValues:  {"Low", "Medium", "High"},
                    value:         local!manualEffort,
                    saveInto:      local!manualEffort,
                    required:      true()
                  )
                }
              ),
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "How often do errors occur?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Error Frequency",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Rarely", "Occasionally", "Frequently"},
                    choiceValues:  {"Rarely", "Occasionally", "Frequently"},
                    value:         local!errorFrequency,
                    saveInto:      local!errorFrequency,
                    required:      true()
                  )
                }
              ),
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "Is the process execution time considered excessive?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Processing Time",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Yes", "No"},
                    choiceValues:  {"Yes", "No"},
                    value:         local!processingTime,
                    saveInto:      local!processingTime,
                    required:      true()
                  )
                }
              )
            }
          ),
          a!columnsLayout(
            columns: {
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "How likely is organizational resistance to automation?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Employee Resistance",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Low", "Medium", "High"},
                    choiceValues:  {"Low", "Medium", "High"},
                    value:         local!employeeResistance,
                    saveInto:      local!employeeResistance,
                    required:      true()
                  )
                }
              ),
              a!columnLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text:  "Would employees require significant training?",
                      color: "SECONDARY",
                      size:  "SMALL"
                    )
                  ),
                  a!radioButtonField(
                    label:         "Training Needs",
                    labelPosition: "COLLAPSED",
                    choiceLabels:  {"Low", "Medium", "High"},
                    choiceValues:  {"Low", "Medium", "High"},
                    value:         local!trainingNeeds,
                    saveInto:      local!trainingNeeds,
                    required:      true()
                  )
                }
              ),
              a!columnLayout(contents: {})
            }
          )
        }
      ),

      /* ============================================================
       * CONFERMA INVIO
       * ============================================================ */
      a!sectionLayout(
        showWhen:  local!submitted,
        label:     "Assessment Submitted",
        labelSize: "MEDIUM",
        contents: {
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: {
              a!richTextItem(
                text:  "Thank you! Your process assessment has been submitted successfully.",
                color: "POSITIVE",
                style: "STRONG",
                size:  "LARGE"
              ),
              char(10), char(10),
              a!richTextItem(text: "Process: ",    style: "STRONG"),
              a!richTextItem(text: local!processName),
              char(10),
              a!richTextItem(text: "Department: ", style: "STRONG"),
              a!richTextItem(text: local!department),
              char(10), char(10),
              a!richTextItem(
                text:  "The results will be used to calculate the automation readiness score.",
                color: "SECONDARY",
                size:  "SMALL"
              )
            }
          )
        }
      ),

      /* ============================================================
       * NAVIGAZIONE WIZARD
       * ============================================================ */
      a!columnsLayout(
        showWhen: not(local!submitted),
        columns: {
          a!columnLayout(
            width: "NARROW",
            contents: {
              a!buttonArrayLayout(
                buttons: {
                  a!buttonWidget(
                    label:    "Back",
                    style:    "GHOST",
                    showWhen: local!currentStep > 1,
                    saveInto: a!save(local!currentStep, local!currentStep - 1)
                  )
                }
              )
            }
          ),
          a!columnLayout(contents: {}),
          a!columnLayout(
            width: "NARROW",
            contents: {
              a!buttonArrayLayout(
                align: "END",
                buttons: {
                  a!buttonWidget(
                    label:    "Next",
                    style:    "SOLID",
                    showWhen: local!currentStep < local!totalSteps,
                    saveInto: a!save(local!currentStep, local!currentStep + 1)
                  ),
                  a!buttonWidget(
                    label:    "Submit Assessment",
                    style:    "SOLID",
                    showWhen: local!currentStep = local!totalSteps,
                    validate: true(),
                    saveInto: a!save(local!submitted, true())
                  )
                }
              )
            }
          )
        }
      )

    }
  )
)
