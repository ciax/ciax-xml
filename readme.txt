## Install required (Debian squeeze) ##
ruby1.9.1 (for using JSON)
libxml-ruby1.9.1 (XML instead of REXML)
libxml2-utils (xmllint)
socat
libsqlite3-ruby1.9.1

## Verbose mode ##
set VER environment
VER=string1,string2... for set sum
VER=string1:strint2..  for set intersection

## String restriction ##
adb//cmdset@id -> never use ':'

### Substitution Strings (implicit conversion) ###
 ## Process order: repeat -> parameter -> status -> formula -> format(w/eval)

 $_ $a..z
    description : substitute sequence number(in repeat)
    usable: fdb//cmdframe/repeat/char
            --
            adb//cmdset/repeat/command/argv
            adb//status/repeat/value/*@ref
            adb//status/repeat/value/binary@bit
            adb//watch/repeat//argv

 $1..9
    description : substitute parameters, sould be numerical
    usable: fdb//cmdframe/char
            fdb//response/array/index
            --
            adb//cmdset/command/argv (eval if @format exists, Math included)

 ${*:*}
    description : substitute status ${k1:k2:idx} => var[k1][k2][idx]
                  content should be numerical expression or of csv array
                  idx can be equation (i.e. $_+1 )
    usable: fdb//cmdframe/char

 $#
    description : formula parameter
    usable: adb//status/value/float@formula

 %? (Format string)
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

### Valid Data ###

 numerical (i.e. '1234','0012','0xab','1+2'..)
    fdb//cmdframe/char
    fdb//cmdframe/string (with @format)
    --   
    adb//cmdset/command/argv (with @format, including Math functions)
   


### Explicit conversion by Attributes ###

 format
    usable: fdb//string
            --
            adb//command/argv
            adb//status/value/float
            adb//status/value/int

 decode
    usable: fdb//response/field
            fdb//response/array

 range
    description: To validate parameters
    example: "0:<10,98,99"
    usable: fdb//char
            --
            adb//command/argv
 
### Reference Content ###
  fdb//cmdframe//command@response <= fdb//rspframe//response@id
  adb//(commands|watch)//frmcmd@name <= fdb//command@id
  adb//watch/interrupt@name <= fdb//command@id
  adb//watch//condition/value@ref <= adb//value@id
  *@symbol <= *//symbol/table@id


### Structure of Data ###
  FIELD:

  STAT: {}
        id => data 
        ...

  VIEW: {}
        "id" => ID
        "class" => class
        "frame" => frame
        "stat" => {}
           id => val
        "symbol" =>{}
           id => {"type","class","msg"}
           ...

### Struct of Db ###
  FrmDb
    ::command
      :label
         id=>Label String
         ...
      :response
         ref=> Status ID
         ...
      :nocache
         id=> true or false
         ...         
    ::status
      :label
         id=>Label String
         ...
      :symbol
         id=>Table ID
         ...
    ::frame (Common part)
      :command
         :main=>[ {data1},{data2} ..]
         :ccrange=>[ {data1},{data2} ..]
         :select
           id=>[ {data1},{data2} ..]
           ...
      :status
         :main=>[ {val1},{val2} ..]
         :ccrange=>[ {val1},{val2} ..]
         :select
           id=>[ {val1},{val2} ..]
           ...
    ::symbol (Tables)
       table1=>{table}
       table2=>{table}

  AppDb
    { "id" ,"frame", "label", "interval }
    :command
      :structure
        id => [ statement,.. ]
           statement=["cmd",{arg1},{arg2}..]
        ...
      :label => {}
        id => Label String
    :status
      "talbe"=> Symbol Table
      :structure
        id => [ { :type, "ref" .. },... ]
        ...
      :label => {}
        id => Label String
      :group => []
        [ Title, [ id1, id2,.. ] ]
        ...
      :symbol => {}
        id => Symbol Table ID
        ..
    :watch => []
        {:type, :var=>{variable},.. }
          :period => second
          :condition => {:operator, :ary => [ {:ref,:val},.. ] }
          :command => [ [statement],.. ]
          :blocking => regexp
          :interrupt => [ [statement],..]

  SymDb
     id => { label, type, :record}
       :record => {}
         id=>{ class,msg }
         ...
