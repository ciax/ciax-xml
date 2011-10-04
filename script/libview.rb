#!/usr/bin/ruby
require "libmsg"
require "libstat"
require "libsymdb"
# Status to View (String with attributes)
class View < Stat
  def initialize(id=nil,adb={})
    super('view',id)
    @symbol=adb[:symbol]||{}
    @sdb=SymDb.new.add('all').add(adb['table'])
    self['stat']={}
  end

  def upd
    self['stat'].each{|key,val|
      next if val == ''
      next unless sid=@symbol[key]
      unless tbl=@sdb[sid]
        Msg.warn("Table[#{sid}] not exist")
        next
      end
      @v.msg{"ID=#{key},table=#{sid}"}
      {'class' => 'alarm','msg' => 'N/A'}.each{|k,v|
        (self[k]||={})[key]=v
      }
      tbl.each{|hash|
        case hash['type']
        when 'range'
          next unless ReRange.new(hash['val']) == val
          @v.msg{"VIEW:Range:[#{hash['val']}] and [#{val}]"}
          self['msg'][key]=hash['msg']+"(#{val})"
        when 'pattern'
          next unless /#{hash['val']}/ === val || val == 'default'
          @v.msg{"VIEW:Regexp:[#{hash['val']}] and [#{val}]"}
          self['msg'][key]=hash['msg']
        end
        self['class'][key]=hash['class']
        break
      }
    }
    self
  end
end
