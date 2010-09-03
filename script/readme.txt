### Substitution Strings (implicit conversion) ###

 $_ $a..z
    description : substitute sequence number(in repeat)
    usable: ddb//response/repeat/field/assign
            --
            cdb//session/repeat/statement/par
            cdb//status/repeat/value/@id
            cdb//status/repeat/value/*@field
            --
            odb//session/repeat/statement/par
            odb//status/repeat/var@id
            odb//status/repeat/var@label
            odb//status/repeat/var/value/*@field

 $_
    description : substitute parameter in calc
    usable: ddb//cmdselect/command/par@calc

 $1..9
    description : substitute parameters
    usable: ddb//response/field/assign
            --
            cdb//session/statement/argv
            --
            odb//session/statement/argv

 ${*:*}
    description : substitute status(field)
    usable: cdb//session/statement/argv
            --
            odb//session/statement/argv
 # No parenthetic variable is processed prior to parenthetic one



 \?
    description : convert escape characters
    usable: ddb//rspframe@terminator

### Explicit conversion by Attributes ###

 format
    usable: ddb//repeat
            ddb//data
            ddb//cmdselect/command/par
            ddb//cmdframe/cc
            --
            cdb//repeat
            cdb//statement
            cdb//status/value
            --
            odb//repeat
            odb//statement
            odb//status/var/value

 decode
    usable: ddb//response/field

 encode
    usable: ddb//cmdselect/command/*
            ddb//cmdframe/*

 validate
 