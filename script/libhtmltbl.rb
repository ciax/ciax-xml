#!/usr/bin/ruby
# Status to View (String with attributes)
require "json"
require "libsymdb"
require "libsymbols"
require "liblabel"
require "libarrange"
class HtmlTbl < Hash
  def initialize(odb)
    ary=self['list']=[{'id'=>'time'}]
    @odb=odb
    @id=odb['id']
    odb.status[:row].each{|k,v|
      ary << {'id'=>k, 'val'=>v}
    }
    Label.new(odb).convert(self)
    Arrange.new(odb).convert(self)
    @sdb=SymDb.new
  end

  def tables
    "SDB="+JSON.dump(@sdb)
  end

  def symbols
    "SYM="+JSON.dump(@odb.status[:symbol])
  end

  # Filterling values by env value of VAL
  # VAL=a:b:c -> grep "a|b|c"
  def to_s
    row=''
    col=self['col']*2+2
    list=[]
    list << "<table><tr>"
    list << "<th colspan=#{col}>#{@id}</th>"
    self['list'].each{|h|
      colspan=(h['id'] == 'time')? " colspan=#{col-1}" : ''
      id="id=\"#{h['id']}\""
      if row != h['row']
        row=h['row']
        list << "</tr><tr>"
      end
      list << "<td class=\"label\">#{h['label']}</td>"
      list << "<td#{colspan}><div #{id} class=\"normal\">*******</div></td>"
    }
    list << "</tr></table>"
    list.join("\n")
  end
end
