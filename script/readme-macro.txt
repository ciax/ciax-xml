# Modes Legend:
#   AS: Actual Status?
#   FE: Force Entering
#   IG: Ignore Error
#   QW: Query? (Interactive?)
#   MV: Moving Command Execution
#   RI: Retry with Interval Second
#   RC: Recording?
#
# Mode              | AS  | FE  | IG  | QW  | MV  | RI| RC
#-------------------+-----+-----+-----+-----+-----+---+-----
# TEST(default):    | NO  | YES | YES | YES | NO  | 0 | NO
# BROWSE(-n):       | NO  | YES | YES | NO  | NO  | 0 | NO
# DRYRUN(-d):       | YES | NO  | NO  | YES | NO  | 1 | NO
# INTERACTIVE(-e):  | YES | NO  | NO  | YES | YES | 1 | YES
# NONSTOP(-ne):     | YES | NO  | NO  | NO  | YES | 1 | YES

# Client Mode
# Macro Client(-c):   mcr level client (connect to mcrsv)
# App Client (-ce):   app level client (connect to dvsv)

# TEST: query(exec,error,enter), interval=0
# REAL: query(exec,error), interval=1
