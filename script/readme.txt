### Substitution Strings (implicit conversion) ###

 $_ 
    description : substitute sequence number(in repeat)
    usable: ddb//assign
            odb//statement/{cmd | par}
            odb//status/var@{id | label}
            odb//status/var/{string | int| float}@field

 $1..9
    description : substitute parameters
    usable: ddb//assign
            odb//statement/par

 ${??}
    description : substitute status(field)
    usable: odb//statement/par

 \?
    description : convert escape characters
    usable: ddb//data
            ddb//rspframe@terminator
            ddb//verify

 %?
    description : sprintf by parameters
    usable: odb/statement/cmd

### Explicit conversion by Attributes ###

 format
    usable: ddb//repeat
            ddb//field
            ddb//par
            ddb//cc_cmd
            odb//float