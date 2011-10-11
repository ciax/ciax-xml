#!/usr/bin/ruby
require "libmsg"
require "libsymdb"
require "libappstat"
# Status to Wview (String with attributes)
class SymStat
  def initialize(adb,view)
    @v=Msg::Ver.new('symbol',2)
    ads=Msg.type?(adb,AppDb)[:status]
    @symbol=ads[:symbol]||{}
    @sdb=SymDb.new.add('all').add(ads['table'])
    @view=Msg.type?(view,Rview)
  end

  def upd
    @symbol.each{|key,sid|
      unless tbl=@sdb[sid]
        Msg.warn("Table[#{sid}] not exist")
        next
      end
      @v.msg{"ID=#{key},table=#{sid}"}
      {'class' => 'alarm','msg' => 'N/A'}.each{|k,v|
        (@view[k]||={})[key]=v
      }
      val=@view['stat'][key]
      tbl.each{|sym|
        case sym['type']
        when 'range'
          next unless ReRange.new(sym['val']) == val
          @v.msg{"VIEW:Range:[#{sym['val']}] and [#{val}]"}
          @view['msg'][key]=sym['msg']+"(#{val})"
        when 'pattern'
          next unless /#{sym['val']}/ === val || val == 'default'
          @v.msg{"VIEW:Regexp:[#{sym['val']}] and [#{val}]"}
          @view['msg'][key]=sym['msg']
        end
        @view['class'][key]=sym['class']
        break
      }
    }
    @view['class']['time']='normal'
    @view['msg']['time']=Time.at(@view['stat']['time'].to_f).to_s
    self
  end
end
