#!/usr/bin/ruby
require "libverbose"
require "librerange"

class Symbols
  def initialize(ref)
    raise "Sym have to be given Hash" unless ref.kind_of?(Hash)
    @v=Verbose.new("Symbol",6)
    @table=ref[:tables]
    @ref=ref[:status][:symbol]||{}
  end

  def convert(view)
    view['list'].each{|k,v|
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
      when 'string'
        val='default' unless tbl.key?(val)
        v.update(tbl[val])
        @v.msg{"VIEW:String:[#{val}](#{tbl[val]['msg']})"}
      end
    }
    self
  end
end
