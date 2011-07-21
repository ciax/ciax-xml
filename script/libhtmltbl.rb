#!/usr/bin/ruby
# Status to View (String with attributes)
require "libsymdb"
require "libsymtbls"
require "liblabel"
require "libarrange"
class HtmlTbl < Hash
  def initialize(odb)
    ary=self['list']=[{'id'=>'time'}]
    @id=odb['id']
    odb.status[:row].each{|k,v|
      ary << {'id'=>k, 'val'=>v}
    }
    Label.new(odb).convert(self)
    Arrange.new(odb).convert(self)
    sym=SymDb.new.update(odb.tables)
    @sdb=SymTbls.new(sym,odb)
  end

  # Filterling values by env value of VAL
  # VAL=a:b:c -> grep "a|b|c"
  def to_s
    row=''
    maxcol=0
    list=[]
    self['list'].each{|h|
      colspan=(h['id'] == 'time')? ' colspan=20' : ''
      if maxcol < col=h['col'].to_i
        maxcol=col
      end
      if row != h['row']
        row=h['row']
        list << "</tr><tr>"
      end
      list << "<td class=\"label\">#{h['label']}</td>"
      list << "<td#{colspan}><div id=\"#{h['id']}\" class=\"normal\">*******</div></td>"
    }
    list << "</tr></table>"
    head=[]
    head << "<table><tr>"
    head << "<th colspan=#{maxcol*2+2}>#{@id}</th>"
    (head+list).join("\n")
  end
end
