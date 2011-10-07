#!/usr/bin/ruby
require "libmsg"
require "librview"
require "libsymdb"
# Status to Wview (String with attributes)
class Wview < Rview
  def initialize(id,adb)
    super(id)
    ads=Msg.type?(adb,AppDb)[:status]
    @symbol=ads[:symbol]||{}
    @sdb=SymDb.new.add('all').add(ads['table'])
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

  def save
    open(@uri,'w'){|f| f << self.to_j }
    self
  end
end
