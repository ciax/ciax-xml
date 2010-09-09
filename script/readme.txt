### Substitution Strings (implicit conversion) ###

 $_ $a..z
    description : substitute sequence number(in repeat)
    usable: cdb//session/repeat/statement/par
            cdb//status/repeat/value/@id
            cdb//status/repeat/value/*@field
            --
            odb//session/repeat/statement/par
            odb//status/repeat/var@id
            odb//status/repeat/var@label
            odb//status/repeat/var/value/*@field

 $1..9
    description : substitute parameters
    usable: ddb//response/field/assign
            --
            cdb//session/statement/eval
            --
            odb//session/statement/eval

 ${*:*}
    description : substitute status(field)
    usable: ddb//cmdframe/eval
            --
            cdb//session/statement/text
            cdb//session/statement/eval
            --
            odb//session/statement/text
            odb//session/statement/eval
 # No parenthetic variable is processed prior to parenthetic one

 \?
    description : convert escape characters
    usable: ddb//rspframe@terminator

### Explicit conversion by Attributes ###

 format
    usable: ddb//data
            ddb//eval
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
            ddb//eval

 validate
 