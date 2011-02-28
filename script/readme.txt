## String restriction ##
cdb//session@id -> never use ':'

### Substitution Strings (implicit conversion) ###

 $_ $a..z
    description : substitute sequence number(in repeat)
    usable: fdb//cmdframe/repeat/data[@type=formula]
            --
            cdb//session/repeat/statement/argv@formula
            cdb//watch/repeat/event@*
            cdb//watch/repeat/event/*/@*
            cdb//status/repeat/value@id
            cdb//status/repeat/value@label
            cdb//status/repeat/value/*@ref
            cdb//status/repeat/value/binary@bit
            --
            odb//session/repeat/statement/par
            odb//status/repeat/var@id
            odb//status/repeat/var@label
            odb//status/repeat/var/value/*@field

 $1..9
    description : substitute parameters
    usable: fdb//cmdframe/data[@type=formula]
            fdb//response/array/index
            --
            cdb//session/statement/argv@formula
            --
            odb//session/statement/formula

 $#
    description : formula parameter
    usable: cdb//status/value/float@formula

 ${*:*}
    description : substitute status ${k1:k2:idx} => var[k1][k2][idx]
    usable: fdb//cmdframe/data[@type=formula]
            --
            odb//session/statement/text
            odb//session/statement/formula
 # No parenthetic variable is processed prior to parenthetic one
 # idx can be equation (i.e. $_+1 )

 \?
    description : convert escape characters
    usable: fdb//rspframe@terminator
            fdb//rspframe@delimiter

### Explicit conversion by Attributes ###

 format
    usable: fdb//data
            fdb//formula
            --
            cdb//repeat
            cdb//statement
            cdb//status/value
            --
            odb//repeat
            odb//statement
            odb//status/var/value

 decode
    usable: fdb//response/field

 encode
    usable: fdb//data
            fdb//formula

 validate
 
### Reference Content ###
  cdb//statement@format <= fdb//command@id + par
  cdb//event/command <= cdb//session@id + par
  cdb//event/while@ref <= cdb//value@id
