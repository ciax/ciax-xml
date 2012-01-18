#!/usr/bin/ruby
require "libmsg"
require "libsymdb"
require "libappstat"
# Status to Wview (String with attributes)
class SymStat < Hash
  def initialize(adb,stat)
    @v=Msg::Ver.new(self,2)
    ads=Msg.type?(adb,AppDb)[:status]
    @symbol=ads[:symbol]||{}
    @sdb=['all',ads['table']].inject({}){|h,k| h.update(SymDb.new(k))}
    self['stat']=Msg.type?(stat,AppStat)
    self['class']={'time' => 'normal'}
    self['msg']={}
  end

  def upd
    @symbol.each{|key,sid|
      unless tbl=@sdb[sid]
        Msg.warn("Table[#{sid}] not exist")
        next
      end
      @v.msg{"ID=#{key},table=#{sid}"}
      {'class' => 'alarm','msg' => 'N/A'}.each{|k,v|
        self[k][key]=v
      }
      val=self['stat'][key]
      tbl.each{|sym|
        case sym['type']
        when 'range'
          next unless ReRange.new(sym['val']) == val
          @v.msg{"VIEW:Range:[#{sym['val']}] and [#{val}]"}
          self['msg'][key]=sym['msg']+"(#{val})"
        when 'pattern'
          next unless /#{sym['val']}/ === val || val == 'default'
          @v.msg{"VIEW:Regexp:[#{sym['val']}] and [#{val}]"}
          self['msg'][key]=sym['msg']
        end
        self['class'][key]=sym['class']
        break
      }
    }
    self['msg']['time']=Time.at(self['stat']['time'].to_f).to_s
    self
  end
end
