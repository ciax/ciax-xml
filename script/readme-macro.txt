# Macro Modes

 *Test Options
  (none) : Listing commands with interaction
   -n    : Listing command with forcing to enter all the case

 *Device Driver Options
   -e  : Device Driver Running Internally
   -l  : Client to Device Serverr (connect to dvsv)

 *Processing Options
   -d  : Processing without Device Execution
   -e  : Processing with internal Device Driver
   -l  : Processing with external Device Server

 *Client Option
   -c  : Client to Macro Server (connect to mcrsv)

# Function Table
  Legend:
   AS: Actual Status?
   DV: Device Driver Running?
   FE: Force Entering
   IG: Ignore Error
   QW: Query? (Interactive?)
   MV: Moving Command Execution
   RI: Retry with Interval Second
   RC: Recording?

  Opt  |AS |DV |FE |IG |QW |MV |RI |RC | Description
 ------+---+---+---+---+---+---+---+---+------------

 *Test mode (Listing)
       | N | N | Y | Y | Y | N | 0 | N | Interactive(default)
 (-n)  | N | N | Y | Y | N | N | 0 | N | Browsing

 *DryRun mode (Processing w/o Actual Device Driver Data)
 (-d)  | N | N | N | N | Y | N | 1 | N | Interactive DryRun
 (-dn) | N | N | N | N | N | N | 1 | N | Nonstop DryRun

 *DryRun mode (Processing w/Device Driver Running)
 (-ed) | Y | Y | N | N | Y | N | 1 | N | Interactive DryRun
 (-edn)| Y | Y | N | N | N | N | 1 | N | Nonstop DryRun

 *DryRun mode (Processing w/Client to Device Driver)
 (-ld) | Y | N | N | N | Y | N | 1 | N | Interactive DryRun
 (-ldn)| Y | N | N | N | N | N | 1 | N | Nonstop DryRun

 *Real Motion (Processing w/Device Driver Running)
 (-e)  | Y | Y | N | N | Y | Y | 1 | Y | Interactive
 (-en) | Y | Y | N | N | N | Y | 1 | Y | Nonstop

 *Real Motion (Processing w/Client to Device Driver)
 (-l)  | Y | N | N | N | Y | Y | 1 | Y | Interactive
 (-ln) | Y | N | N | N | N | Y | 1 | Y | Nonstop


# TEST: query(exec,error,enter), interval=0
# DRY : query(error), interval=0
# REAL: query(exec,error), interval=1
