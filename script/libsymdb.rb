#!/usr/bin/ruby
require "libmsg"
require "libmodcache"
require "librerange"

class SymDb < Hash
  include ModCache
  def initialize(gid='all',nocache=nil) # gid = Table Group ID
    @v=Msg::Ver.new("Symbol",6)
    cache('sdb',gid,nocache){|doc|
      hash=Hash[doc]
      doc.top.each{|e1|
        row=e1.to_h
        id=row.delete('id')
        label=row['label']
        e1.each{|e2| # case
          key=e2.text||"default"
          (row[:record]||={})[key]=e2.to_h
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
    vs=view['symbol']||={}
    view['stat'].each{|k,val|
      next if val == ''
      next unless sid=@ref[k]
      tbl=table(sid) || next
      @v.msg{"ID=#{k},ref=#{sid}"}
      case self[sid]['type']
      when 'range'
        tbl.each{|match,hash|
          next unless ReRange.new(match) == val
          @v.msg{"VIEW:Range:[#{match}] and [#{val}]"}
          vs[k]={'type' => 'num'}.update(hash)
          break
        }
      when 'regexp'
        tbl.each{|match,hash|
          @v.msg{"VIEW:Regexp:[#{match}] and [#{val}]"}
          next unless /#{match}/ === val || val == 'default'
          vs[k]={'type' => 'str'}.update(hash)
          break
        }
      when 'string'
        val='default' unless tbl.key?(val)
        @v.msg{"VIEW:String:[#{val}](#{tbl[val]['msg']})"}
        vs[k]={'type' => 'str'}.update(tbl[val])
      end
    }
    self
  end

  private
  def table(id)
    if key?(id)
      tbl=(self[id][:record]||={})
      unless tbl.key?('default')
        tbl['default']={'class' => 'alarm','msg' => 'N/A'}
      end
      tbl
    else
      Msg.warn("Table[#{id}] not exist")
      false
    end
  end
end

if __FILE__ == $0
  begin
    sdb=SymDb.new(ARGV.shift,true)
  rescue SelectID
    warn "USAGE: #{$0} [id]"
    Msg.exit
  end
  puts sdb
end
