### Substitution Strings (implicit conversion) ###

 $_ 
    description : substitute sequence number(in repeat)
    usable: ddb//response/repeat/field/assign
            odb//session/repeat/statement/par
            odb//status/repeat/var@id
            odb//status/repeat/var@label
            odb//status/repeat/var/int@field
            odb//status/repeat/var/float@field
            odb//status/repeat/var/string@field

 $1..9
    description : substitute parameters
    usable: ddb//response/field/assign
            odb//session/statement/par

 ${??}
    description : substitute status(field)
    usable: odb//session/statement/par

 \?
    description : convert escape characters
    usable: ddb//data
            ddb//rspframe@terminator
            ddb//verify

### Explicit conversion by Attributes ###

 format
    usable: ddb//command/par
            ddb//cmdframe/cc
            ddb//response/repeat
            ddb//response/field
            odb//statement
            odb//status/float

 decode
    usable: ddb//response/field

 encode
    usable: ddb//command/data
            ddb//command/par
            ddb//cmdframe/cc
 validate
 
