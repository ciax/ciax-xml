#!/usr/bin/ruby
require "libmsg"
require "libsymdb"
require "libappval"
# Status to Stat::Writable (String with attributes)
class SymStat
  attr_reader :msg,:cls
  def initialize(adb,val)
    @v=Msg::Ver.new(self,2)
    ads=Msg.type?(adb,AppDb)[:status]
    @symbol=ads[:symbol]||{}
    @sdb=SymDb.pack(['all',ads['table']])
    @val=Msg.type?(val,AppVal)
    @cls={'time' => 'normal'}
    @msg={}
  end

  def upd
    @symbol.each{|key,sid|
      unless tbl=@sdb[sid]
        Msg.warn("Table[#{sid}] not exist")
        next
      end
      @v.msg{"ID=#{key},table=#{sid}"}
      @cls[key]='alarm'
      @msg[key]='N/A'
      val=@val[key]
      tbl.each{|sym|
        case sym['type']
        when 'range'
          next unless ReRange.new(sym['val']) == val
          @v.msg{"VIEW:Range:[#{sym['val']}] and [#{val}]"}
          @msg[key]=sym['msg']+"(#{val})"
        when 'pattern'
          next unless /#{sym['val']}/ === val || val == 'default'
          @v.msg{"VIEW:Regexp:[#{sym['val']}] and [#{val}]"}
          @msg[key]=sym['msg']
        end
        @cls[key]=sym['class']
        break
      }
    }
    stime=@val['time'].to_f
    @msg['time']=Time.at(stime).to_s
    @v.msg{"Update(#{stime})"}
    self
  end
end
