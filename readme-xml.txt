## Layer description ##

  frm: Frame layer
       classified by communication protocol (frame format)
       transaction: sync
  app: Application layer
       classified by model number (application)
       transaction: async
  wat: Watch layer
       associated with app id
       function: automated command issue according to the status
                 block conflicting commands
                 appropriate command for interrupt. 
  mcr: Macro layer

  ins/dev: Site Layer
       classified by site id (dev=>frm, ins=>app)
       function: aliasing, symboling and labeling over adb items
       information: host, port

## DB description ##

  fdb: Frame DB
    fdbc: Command DB
    fdbs: Status DB
  adb: Apprication DB
    adbc: Command DB
    adbs: Status DB
  ddb: Device DB (Frm site information)
  idb: Instance DB (App site information)
  sdb: Symbol DB
      used by adb or idb
  cdb: Command Alias DB
      used by idb
  wdb: Watch DB
      included in adb      
  mdb: Macro DB

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
    description : substitute sequence number(in repeat), expanded in Db
      with eval(calc strings which is separated with ':'):
            //repeat@[from,to]
            --
            fdb//cmdframe/repeat/[char,string]
            --
            adb//commands/repeat/command/argv
            adb//status/repeat/value/[int,float,binary]@index
            adb//status/repeat/value/binary@bit
            adb//status//value/repeat_field/*@index,@bit
            adb//watch/repeat//argv
      with format string;
            adb//status/repeat/value@[id,label,group]
            adb//watch/repeat/event@[id,label]
            adb//watch/repeat/event/pattern@var

 $1..9
    description : substitute parameters, sould be numerical
    available: fdb//command/[char,string]
            fdb//response/array/index@range (separated by : )
            --
            adb//command/argv (eval if @format exists, Math and condition operator (a ? b : c) included)

 ${*@*}
    description : substitute status ${key@idx@idx} => var[key][idx][idx]
                  content should be numerical expression or of csv array
                  idx can be equation (i.e. $_+1 )
    available: fdb//command/[char,string]

 ${*:*/*}
    description : substitute status ${token}
                  token is layer:category/key => var[layer][category][key]
                  content should be string
    available: adb//command/argv

 $#
    description : formula parameter
    available: adb//status/value@formula

 \?
    description : convert escape characters
    available: fdb//rspframe@terminator
            fdb//rspframe@delimiter

### Explicit conversion by Attributes ###

 format (using %? string)
    available: fdb//string
            --
            adb//command/argv
            adb//status/value

 formula (using $#)
    available: adb//status/value/float

 decode
    available: fdb//response/field
            fdb//response/array

 range
    description: To validate parameters
    example: "0:<10,98,99"
    available: fdb//command/par_num
            --
            adb//command/par_num
            adb//status/binary/field@bit
            adb//event/range

### Implicit conversion ###

  numerical sum
    adb//status/value/float
    adb//status/value/int

  binary sum (MSB first)
    adb//status/value/binary

  concat strings
    adb//status/value/string

  format strings (using %s)
    sdb//table/*@msg
    cdb//alias//[unit,item]@label
    adb//command//[unit,item]@label

### Reference Key ###

  fdb//command@response <= fdb//rspframe//response@id
  adb//frmcmd@name <= fdb//command@id
  adb//event/(int,exec,block)@name <= adb//commands/command@id
  adb//event/(onchange,pattern,range)@ref <= adb//status/*@id
  *@symbol <= *//symbol/table@id

### Command Grouping ###
  target: fdb//command, adb//command

  //group: Grouping ether CUI or WEB control section.
    WEB: Controlable Group is selectable (show or hide).

  //unit: group of exclusive commands (conflict each other)
    @title: represents the name of members
    @label: format text. '%s' is replaced with member labels connected by '/'
    WEB: All member gets into one select tab.
         w/@label: Show @label in which format text ([%s]) is removed.
                   -> [@label] [select button]
    CUI: w/@title: Show @title and @label representing the group.
                  Don't show each members. -> [@title]: [@label]
         w/o @title: Show each members. label is ignored.
