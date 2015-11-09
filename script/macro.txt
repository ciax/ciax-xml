  # Modes Legend:
  #   AS: Actual Status?
  #   FE: Force Entering
  #   QW: Query? (Interactive?)
  #   MV: Moving
  #   RI: Retry with Interval
  #   RC: Recording?
  # Mode Table
  # Field             | AS  | FE  | QW  | MV  | RI| RC
  # TEST(default):    | NO  | YES | YES | NO  | 0 | NO
  # NONSTOP TEST(-n): | NO  | YES | NO  | NO  | 0 | NO
  # CHECK(-e):        | YES | YES | YES | NO  | 0 | YES
  # DRYRUN(-ne):      | YES | YES | NO  | NO  | 0 | YES
  # INTERACTIVE(-em): | YES | NO  | YES | YES | 1 | YES
  # NONSTOP(-nem):    | YES | NO  | NO  | YES | 1 | YES

  # MOTION:  TEST <-> REAL (m)
  # QUERY :  INTERACTIVE <-> NONSTOP(n)

  # TEST: query(exec,error,enter), interval=0
  # REAL: query(exec,error), interval=1
