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
      if maxcol < col=h['col'].to_i
        maxcol=col
      end
      if row != h['row']
        row=h['row']
        list << "</tr><tr>"
      end
      list << "<td>#{h['label']}</td><td><div id=\"#{h['id']}\" /></td>"
    }
    list << "</tr></table>"
    list.unshift "<th colspan=#{maxcol*2+2}>#{@id}</th>"
    list.unshift "<table class=\"CIAX\"><tr>"
    list.join("\n")
  end
end
