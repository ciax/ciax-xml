## Layer description ##

  frm: Frame layer
       classified by frame format
       transaction: sync
  app: Application layer
       classified by application
       transaction: async
  ins: Instance layer
       classified by individuality or identity
       function: aliasing, symboling and labeling over adb items

## DB description ##

  fdb: Frame DB
    fdbc: Command DB
    fdbs: Status DB
  adb: Apprication DB
    adbc: Command DB
    adbs: Status DB
  idb: Instance DB
  sdb: Symbol DB
      used by adb or idb
  wdb: Watch DB
      included in adb      

### Data Validation ###

 numerical (i.e. '1234','0012','0xab','1+2'..)
    fdb//char
    fdb//string (with @format)
    --   
    adb//command/argv (with @format, including Math functions)

 token (never use ':')
    adb//command@id

### Substitution Strings ###
 # Process order: repeat -> parameter -> status -> formula -> eval -> format

 $_ $` $a..z
    description : substitute sequence number(in repeat)
    usable: fdb//cmdframe/repeat/[char,string]
            --
            adb//commands/repeat/command/argv
            adb//status/repeat/value/[int,float,binary]@index
            adb//status/repeat/value/binary@bit
            adb//watch/repeat//argv

 $1..9
    description : substitute parameters, sould be numerical
    usable: fdb//command/[char,string]
            fdb//response/array/index@range
            --
            adb//command/argv (eval if @format exists, Math included)

 ${*:*}
    description : substitute status ${key:idx:idx} => var[key][idx][idx]
                  content should be numerical expression or of csv array
                  idx can be equation (i.e. $_+1 )
    usable: fdb//command/[char,string]

 $#
    description : formula parameter
    usable: adb//status/value/float@formula

 %d,%f (Format string)
    description : sprintf with sequence number array (in repeat)
            adb//status/repeat/value@id
            adb//status/repeat/value@label
            adb//status/repeat/value@group
            adb//watch/repeat/*/@ref
            adb//watch/repeat/*/@label
            adb//watch/repeat/*/@blocking
            --
            sdb//symbol/repeat/case@id

 \?
    description : convert escape characters
    usable: fdb//rspframe@terminator
            fdb//rspframe@delimiter

### Explicit conversion by Attributes ###

 format
    usable: fdb//string
            --
            adb//command/argv
            adb//status/value

 formula
    usable: adb//status/value/float

 decode
    usable: fdb//response/field
            fdb//response/array

 range
    description: To validate parameters
    example: "0:<10,98,99"
    usable: fdb//command/par
            --
            adb//command/par
            adb//event/range

### Implicit conversion ###

  numerical sum
    adb//status/value/float
    adb//status/value/int

  binary sum (MSB first)
    adb//status/value/binary

  concat strings
    adb//status/value/string
 
### Reference Key ###

  fdb//command@response <= fdb//rspframe//response@id
  adb//frmcmd@name <= fdb//command@id
  adb//event/(int,exec,block)@name <= adb//commands/command@id
  adb//event/(onchange,pattern,range)@ref <= adb//status/value@id
  *@symbol <= *//symbol/table@id
