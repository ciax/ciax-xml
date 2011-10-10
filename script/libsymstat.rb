#!/usr/bin/ruby
require "libmsg"
require "libsymdb"
# Status to Wview (String with attributes)
class SymStat
  def initialize(adb)
    @v=Msg::Ver.new('symbol',2)
    ads=Msg.type?(adb,AppDb)[:status]
    @symbol=ads[:symbol]||{}
    @sdb=SymDb.new.add('all').add(ads['table'])
  end

  def mksym(stat)
    hash={'class' => {},'msg' => {}}
    @symbol.each{|key,sid|
      unless tbl=@sdb[sid]
        Msg.warn("Table[#{sid}] not exist")
        next
      end
      @v.msg{"ID=#{key},table=#{sid}"}
      {'class' => 'alarm','msg' => 'N/A'}.each{|k,v|
        (hash[k]||={})[key]=v
      }
      val=stat[key]
      tbl.each{|sym|
        case sym['type']
        when 'range'
          next unless ReRange.new(sym['val']) == val
          @v.msg{"VIEW:Range:[#{sym['val']}] and [#{val}]"}
          hash['msg'][key]=sym['msg']+"(#{val})"
        when 'pattern'
          next unless /#{sym['val']}/ === val || val == 'default'
          @v.msg{"VIEW:Regexp:[#{sym['val']}] and [#{val}]"}
          hash['msg'][key]=sym['msg']
        end
        hash['class'][key]=sym['class']
        break
      }
    }
    hash
  end
end
