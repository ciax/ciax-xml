#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"

class SymDb < Hash
  def initialize(doc=nil,db=nil)
    doc ||= XmlDoc.new('sdb','all')
    update(db) if db
    @v=Verbose.new("sdb",6)
    doc.symbol.each{|e1|
      row=e1.to_h
      id=row.delete('id')
      rc=row[:record]={}
      e1.each{|e2| # case
        if e2.text
          rc[e2.text]=e2.to_h
        else
          rc.default=e2.to_h
        end
      }
      self[id]=row
      @v.msg{"Symbol Table:#{id} : #{row}"}
    }
    self
  end

  def to_s
    Verbose.view_struct("Symbol Table",self)
  end
end

if __FILE__ == $0
  db=SymDb.new() rescue ("USAGE: #{$0} [id]\n#{$!}")
  puts db
end
