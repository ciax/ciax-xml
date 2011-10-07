#!/usr/bin/ruby
require "libmsg"
require "libexhash"
require "libsymdb"
# Status to Wview (String with attributes)
class Wview < ExHash
  def initialize(id,adb)
    @v=Msg::Ver.new('view',6)
    ads=Msg.type?(adb,AppDb)[:status]
    @symbol=ads[:symbol]||{}
    @sdb=SymDb.new.add('all').add(ads['table'])
    self['id']=id
    self['stat']={}
    @fname=VarDir+"/json/view_#{id}.json"
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
    open(@fname,'w'){|f| f << self.to_j }
    self
  end
end
