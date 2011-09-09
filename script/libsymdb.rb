#!/usr/bin/ruby
require "libmsg"
require "libcache"
require "librerange"

class SymDb < Hash
  include Cache
  def initialize(id='all',nocache=nil)
    @v=Msg::Ver.new("Symbol",6)
    cache('sdb',id,nocache){|doc|
      hash=Hash[doc]
      doc.top.each{|e1|
        row=e1.to_h
        id=row.delete('id')
        label=row['label']
        rc=row[:record]={}
        e1.each{|e2| # case
          key=e2.text||"default"
          rc[key]=e2.to_h
        }
        hash[id]=row
        @v.msg{"Symbol Table:#{id} : #{label}"}
      }
      hash
    }
  rescue SelectID
    raise $! if __FILE__ == $0
  end

  def convert(view,ref=nil)
    @ref=ref||@ref
    view['symbol']||={}
    view['stat'].each{|k,val|
      next if val == ''
      next unless sid=@ref[k]
      unless key?(sid)
        Msg.warn("Table[#{sid}] not exist")
        next
      end
      @v.msg{"ID=#{k},ref=#{sid}"}
      tbl=self[sid][:record]
      case self[sid]['type']
      when 'range'
        tbl.each{|match,hash|
          next unless ReRange.new(match) == val
          view['symbol'][k]={'type' => 'num'}.update(hash)
          @v.msg{"VIEW:Range:[#{match}] and [#{val}]"}
          break
        }
      when 'regexp'
        tbl.each{|match,hash|
          @v.msg{"VIEW:Regexp:[#{match}] and [#{val}]"}
          next unless /#{match}/ === val || val == 'default'
          view['symbol'][k]={'type' => 'str'}.update(hash)
          break
        }
      when 'string'
        val='default' unless tbl.key?(val)
        view['symbol'][k]={'type' => 'str'}.update(tbl[val])
        @v.msg{"VIEW:String:[#{val}](#{tbl[val]['msg']})"}
      end
    }
    self
  end
end

if __FILE__ == $0
  begin
    sdb=SymDb.new(ARGV.shift,true)
  rescue SelectID
    abort "USAGE: #{$0} [id]\n#{$!}"
  end
  puts sdb
end
