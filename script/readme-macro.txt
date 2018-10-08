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
   PR: Processing?
   AS: Actual Status?
   DV: Device Driver Running?
   FE: Force Entering
   IG: Ignore Error
   QW: Query? (Interactive?)
   MV: Moving Command Execution
   RI: Retry with Interval Second
   RC: Recording?
   LO: Logging at Device Level?

  Opt  |PR |AS |DV |FE |IG |QW |MV |RI |RC |LO | Description
 ------+---+---+---+---+---+---+---+---+---+---+------------

 *Test mode (Processing w/o Actual Device Driver Data)
       | Y | N | N | N | Y | Y | N | 1 | N | N | Interactive DryRun
 (-n)  | Y | N | N | N | Y | N | N | 1 | N | N | Nonstop DryRun

 *DryRun mode (Processing w/Device Driver Running, No execution)
 (-d)  | Y | Y | Y | N | N | Y | N | 1 | N | Y | Interactive DryRun
 (-dn) | Y | Y | Y | N | N | N | N | 1 | N | Y | Nonstop DryRun

 *DryRun mode (Processing w/Client to Device Driver, No execution)
 (-ld) | Y | Y | N | N | N | Y | N | 1 | N | N |Interactive DryRun
 (-ldn)| Y | Y | N | N | N | N | N | 1 | N | N | Nonstop DryRun

 *Real Motion (Processing w/Device Driver Running)
 (-e)  | Y | Y | Y | N | N | Y | Y | 1 | Y | Y | Interactive
 (-en) | Y | Y | Y | N | N | N | Y | 1 | Y | Y | Nonstop

 *Real Motion (Processing w/Client to Device Driver)
 (-l)  | Y | Y | N | N | N | Y | Y | 1 | Y | N | Interactive
 (-ln) | Y | Y | N | N | N | N | Y | 1 | Y | N | Nonstop


# TEST: query(exec,error,enter), interval=0
# DRY : query(error), interval=0
# REAL: query(exec,error), interval=1
