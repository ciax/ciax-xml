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
    usable: fdb//cmdframe/repeat/code
            --
            adb//cmdset/repeat/command/argv
            adb//status/repeat/value/*@ref
            adb//status/repeat/value/binary@bit
            adb//watch/repeat//argv

 $1..9
    description : substitute parameters, sould be numerical
    usable: fdb//cmdframe/code
            fdb//response/array/index
            --
            adb//cmdset/command/argv (eval if @format exists)

 ${*:*}
    description : substitute status ${k1:k2:idx} => var[k1][k2][idx]
                  content should be numerical expression or of csv array
                  idx can be equation (i.e. $_+1 )
    usable: fdb//cmdframe/code

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

### Explicit conversion by Attributes ###

 format
    usable: fdb//code
            --
            adb//command/argv
            adb//status/value/float
            adb//status/value/int

 decode
    usable: fdb//response/field
            fdb//response/array

 encode
    usable: fdb//code

 range
    description: To validate parameters
    example: "0:<10,98,99"
    usable: fdb//code
            --
            adb//command/argv
 
### Reference Content ###
  fdb//cmdframe//command@response <= fdb//rspframe//response@id
  adb//(commands|watch)//command@name <= fdb//command@id
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
        "list" =>[]
           id => {"val","class","msg"}
           ...
        "label" => { id => label }
           ...
        "group" =>[]
           [ Title, [ id1, id2,.. ] ]
           ...


### Struct of Db ###
  FrmDb
    ::command
      :select
         id=>[ {data1},{data2} ..]
         ...
      :label
         id=>Label String
         ...
    ::status
      :select
         id=>[ {val1},{val2} ..]
         ...
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
      :status
         :main=>[ {val1},{val2} ..]
         :ccrange=>[ {val1},{val2} ..]
    ::symbol (Tables)
       table1=>{table}
       table2=>{table}

  ClsDb
    { "id" ,"frame", "label", "interval }
    ::command
      :select => {}
        id => [ statement,.. ]
           statement=["cmd",{arg1},{arg2}..]
        ...
      :label => {}
        id => Label String
    ::status
      :select => {}
        id => [ { :type, "ref" .. },... ]
        ...
      :group => []
        [ Title, [ id1, id2,.. ] ]
        ...
      :label => {}
        id => Label String
      :symbol => {}
        id => Symbol Table ID
        ..
    ::table (Symbol Table)
        id => { label, type, :record}
          :record => {}
            val=>{ class,msg }
            ...
    ::watch => []
        {:type, :var=>{variable},.. }
          :period => second
          :condition => {:operator, :ary => [ {:ref,:val},.. ] }
          :command => [ [statement],.. ]
          :blocking => regexp
          :interrupt => [ [statement],..]
