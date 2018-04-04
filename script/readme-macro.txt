# Macro Modes

 *Test Options
  (none) : Listing commands with interaction
   -n    : Listing command with forcing to enter all the case

 *Processing Options (-d: modifier)
   -e  : Processing and Device Driver Running
   -l  : Processing and Client for Driver (connect to dvsv)
   -ed : Processing and Device Driver Running with Dryrun (Motion command isn't issued)
   -ld : Processing and Client for Driver with Dryrun

 *Client Option
   -c  : Client for Macro (connect to mcrsv)

# Function Table
  Legend:
   AS: Actual Status?
   FE: Force Entering
   IG: Ignore Error
   QW: Query? (Interactive?)
   MV: Moving Command Execution
   RI: Retry with Interval Second
   RC: Recording?

  Opt  |AS |FE |IG |QW |MV |RI |RC | Description
 ------+---+---+---+---+---+---+---+---------------

 *Test mode (Listing)
       | N | Y | Y | Y | N | 0 | N | Interactive(default)
 (-n)  | N | Y | Y | N | N | 0 | N | Browsing

 *Test mode (Processing)
 (-ld) | Y | N | N | Y | N | 1 | N | Interactive DryRun
 (-ldn)| Y | N | N | N | N | 1 | N | Nonstop DryRun

 *Real Motion (Device Driver Running)
 (-e)  | Y | N | N | Y | Y | 1 | Y | Interactive
 (-en) | Y | N | N | N | Y | 1 | Y | Nonstop

 *Real Motion (Client to Device Driver)
 (-l)  | Y | N | N | Y | Y | 1 | Y | Interactive
 (-ln) | Y | N | N | N | Y | 1 | Y | Nonstop


# TEST: query(exec,error,enter), interval=0
# REAL: query(exec,error), interval=1
