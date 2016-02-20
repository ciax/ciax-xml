# Modes Legend:
#   AS: Actual Status?
#   FE: Force Entering
#   QW: Query? (Interactive?)
#   MV: Moving
#   RI: Retry with Interval
#   RC: Recording?
#
# Mode              | AS  | FE  | QW  | MV  | RI| RC
# TEST(default):    | NO  | YES | YES | NO  | 0 | NO
# DRYRUN(-n):       | NO  | YES | NO  | NO  | 0 | NO
# INTERACTIVE(-e):  | YES | NO  | YES | YES | 1 | YES
# NONSTOP(-ne):     | YES | NO  | NO  | YES | 1 | YES

# Client Mode
# Macro Client(-c):   mcr level client (connect to mcrsv)
# App Client (-ce):   app level client (connect to dvsv)

# TEST: query(exec,error,enter), interval=0
# REAL: query(exec,error), interval=1
