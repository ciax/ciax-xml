### Substitution Strings (implicit conversion) ###

 $_ 
    description : substitute sequence number(in repeat)
    usable: ddb//response/repeat/field/assign
            --
            odb//session/repeat/statement/par
            odb//status/repeat/var@id
            odb//status/repeat/var@label
            odb//status/repeat/var/value/*@field

 $1..9
    description : substitute parameters
    usable: ddb//response/field/assign
            --
            odb//session/statement/argv

 ${??}
    description : substitute status(field)
    usable: odb//session/statement/argv

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
            odb//repeat
            odb//statement
            odb//status/var/value

 decode
    usable: ddb//response/field

 encode
    usable: ddb//cmdselect/command/*
            ddb//cmdframe/*

 validate
 