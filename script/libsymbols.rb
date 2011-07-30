#!/usr/bin/ruby
require "libverbose"
require "librerange"

class Symbols
  def initialize(table,ref)
    raise "Sym have to be given Db" unless ref.kind_of?(Db)
    raise "Sym have to be given SymDb" unless table.kind_of?(SymDb)
    @v=Verbose.new("Symbol",6)
    @table=table
    @ref=ref.status[:symbol]||{}
  end

  def convert(view)
    list=[]
    view['list'].each{|v|
      k=v['id']
      list << v
      val=v['val']
      next if val == ''
      next unless sid=@ref[k]
      @v.msg{"ID=#{k},ref=#{sid}"}
      tbl=@table[sid][:record]
      case @table[sid]['type']
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
      else
        @v.msg{"VIEW:No Symbol Reference:[#{val}]"}
        v.update(@table[sid][:record][val])
      end
    }
    view['list']=list
    self
  end
end
