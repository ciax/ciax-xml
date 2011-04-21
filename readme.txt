## Install required (Debian squeeze) ##
ruby1.9.1 (for using JSON)
libxml-ruby1.9.1 (XML instead of REXML)
libxml2-utils (xmllint)
socat
libsqlite3-ruby1.9.1

## String restriction ##
cdb//session@id -> never use ':'

### Substitution Strings (implicit conversion) ###
 ## Process order: repeat -> parameter -> status -> formula -> format(w/eval)

 $_ $a..z
    description : substitute sequence number(in repeat)
    usable: fdb//cmdframe/repeat/data
            --
            cdb//session/repeat/statement/argv
            cdb//status/repeat/value/*@ref
            cdb//status/repeat/value/binary@bit
            cdb//watch/repeat//argv

 $1..9
    description : substitute parameters, sould be numerical
    usable: fdb//cmdframe/data
            fdb//response/array/index
            --
            cdb//session/statement/argv

 ${*:*}
    description : substitute status ${k1:k2:idx} => var[k1][k2][idx]
                  content should be numerical expression or of csv array
                  idx can be equation (i.e. $_+1 )
    usable: fdb//cmdframe/data

 $#
    description : formula parameter
    usable: cdb//status/value/float@formula

 %? (Format string)
    description : sprintf with sequence number array (in repeat)
            cdb//status/repeat/value@id
            cdb//status/repeat/value@label
            cdb//status/repeat/value@group
            cdb//watch/repeat/*/@ref
            cdb//watch/repeat/*/@label
            cdb//watch/repeat/*/@blocking
            --
            sdb//symbol/repeat/case@id


 \?
    description : convert escape characters
    usable: fdb//rspframe@terminator
            fdb//rspframe@delimiter

### Explicit conversion by Attributes ###

 format
    usable: fdb//data
            --
            cdb//statement/argv
            cdb//status/value/float
            cdb//status/value/int

 decode
    usable: fdb//response/field
            fdb//response/array

 encode
    usable: fdb//data

 range
    description: To validate parameters
    example: "0:<10,98,99"
    usable: fdb//data
            --
            cdb//statement/argv

 
### Reference Content ###
  cdb//statement@format <= fdb//command@id + par
  cdb//event/command <= cdb//session@id + par
  cdb//event/while@ref <= cdb//value@id
