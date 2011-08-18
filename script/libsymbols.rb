#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "librerange"

class Symbols < Hash
  attr_reader :ref
  def initialize(sdb={})
    raise "Sym have to be given Hash" unless sdb.kind_of?(Hash)
    @v=Verbose.new("Symbol",6)
    if sdb.key?(:symbol)
      @ref=sdb[:symbol]
    else
      @ref={}
    end
    add(sdb['table']) if sdb.key?('table')
    add('all')
  end

  def convert(view)
    view['list'].each{|k,v|
      val=v['val']
      next if val == ''
      next unless sid=@ref[k]
      unless key?(sid)
        @v.warn("Table[#{sid}] not exist")
        next
      end
      @v.msg{"ID=#{k},ref=#{sid}"}
      tbl=self[sid][:record]
      case self[sid]['type']
      when 'range'
        tbl.each{|match,hash|
          next unless ReRange.new(match) == val
          v['val']=val.to_f
          v.update(hash)
          @v.msg{"VIEW:Range:[#{match}] and [#{val}]"}
          break
        }
      when 'regexp'
        tbl.each{|match,hash|
          @v.msg{"VIEW:Regexp:[#{match}] and [#{val}]"}
          next unless /#{match}/ === val || val == 'default'
          v.update(hash)
          break
        }
      when 'string'
        val='default' unless tbl.key?(val)
        v.update(tbl[val])
        @v.msg{"VIEW:String:[#{val}](#{tbl[val]['msg']})"}
      end
    }
    self
  end

  def to_s
    Verbose.view_struct(self,"Tables")+Verbose.view_struct(@ref,"Symbol")
  end

  private
  def add(type)
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
end

if __FILE__ == $0
  require 'libclsdb'
  begin
    cdb=ClsDb.new(ARGV.shift)
  rescue SelectID
    abort "USAGE: #{$0} [id]\n#{$!}"
  end
  puts Symbols.new(cdb[:status])
end
