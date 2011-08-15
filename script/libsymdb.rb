#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"

class SymDb < Hash
  def initialize(type='all')
    @v=Verbose.new("sdb",6)
    doc=XmlDoc.new('sdb',type)
    doc.top.each{|e1|
      row=e1.to_h
      id=row.delete('id')
      rc=row[:record]={}
      e1.each{|e2| # case
        key=e2.text||"default"
        rc[key]=e2.to_h
      }
      self[id]=row
      @v.msg{"Symbol Table:#{id} : #{row}"}
    }
    self
  rescue SelectID
    abort "USAGE: #{$0} [id]\n#{$!}" if __FILE__ == $0
  end

  def to_s
    Verbose.view_struct(self)
  end
end

if __FILE__ == $0
  puts SymDb.new(ARGV.shift)
end
