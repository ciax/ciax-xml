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
    @sdb=SymDb.new.update(odb.tables)
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
    row=self['list'].first['row']
    col=self['col']*2+2
    list=[]
    list << "<table class=\"outline\">"
    list << "<thead class=\"title\"><tr>"
    list << "<th class=\"title\"colspan=#{col}>#{@id}</th>"
    list << "</tr></thead>"
    list << "<tbody><tr>"
    self['list'].each{|h|
      colspan=(h['id'] == 'time')? " colspan=#{col-1}" : ''
      id="id=\"#{h['id']}\""
      if row != h['row']
        row=h['row']
        list << "</tr><tr>"
      end
      list << "<td class=\"label\">#{h['label']}</td>"
      list << "<td class=\"value\"#{colspan}>"
      list << "<div #{id} class=\"normal\">*******</div>"
      list << "</td>"
    }
    list << "</tr></tbody>"
    list << "</table>"
    list.join("\n")
  end
end
