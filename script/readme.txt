## String restriction ##
cdb//session@id -> never use ':'

### Substitution Strings (implicit conversion) ###

 $_ $a..z
    description : substitute sequence number(in repeat)
    usable: cdb//session/repeat/statement/formula
            cdb//status/repeat/value@id
            cdb//status/repeat/value/*
            --
            odb//session/repeat/statement/par
            odb//status/repeat/var@id
            odb//status/repeat/var@label
            odb//status/repeat/var/value/*@field

 $1..9
    description : substitute parameters
    usable: ddb//cmdframe/formula
            ddb//cmdframe/csv
            ddb//response/array/index
            --
            cdb//session/statement/formula
            --
            odb//session/statement/formula

 ${*:*}
    description : substitute status ${k1:k2:idx} => var[k1][k2][idx]
    usable: ddb//cmdframe/formula
            ddb//cmdframe/csv
            --
            odb//session/statement/text
            odb//session/statement/formula
 # No parenthetic variable is processed prior to parenthetic one
 # idx can be equation (i.e. $_+1 )

 \?
    description : convert escape characters
    usable: ddb//rspframe@terminator
            ddb//rspframe@delimiter

### Explicit conversion by Attributes ###

 format
    usable: ddb//data
            ddb//formula
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
    usable: ddb//data
            ddb//formula

 validate
 