#!/usr/bin/ruby
require "libmsg"
require "libsymdb"
require "libappval"
# Status to StatW (String with attributes)
class SymStat < Hash
  def initialize(adb,val)
    @v=Msg::Ver.new(self,2)
    ads=Msg.type?(adb,AppDb)[:status]
    @symbol=ads[:symbol]||{}
    @sdb=SymDb.pack(['all',ads['table']])
    self['val']=Msg.type?(val,AppVal)
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
      val=self['val'][key]
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
    stime=self['val']['time'].to_f
    self['msg']['time']=Time.at(stime).to_s
    @v.msg{"Update(#{stime})"}
    self
  end
end
