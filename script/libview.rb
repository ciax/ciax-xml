#!/usr/bin/ruby
require 'libstat'

class View < ExHash
  def initialize(adb,stat)
    @sdb=Msg.type?(adb,AppDb)[:status]
    @stat=Msg.type?(stat,Stat)
    ['val','class','msg'].each{|key|
      stat[key]||={}
    }
    @sdb[:group].each{|k,v|
      cap=@sdb[:caption][k] || next
      self[k]={'caption' => cap,'lines'=>[]}
      col=@sdb[:column][k]||1
      v.each_slice(col.to_i){|ids|
        self[k]['lines'] << get_element(ids)
      }
    }
    self
  end

  private
  def get_element(ids)
    hash={}
    ids.each{|id|
      case id
      when 'elapse'
        str=Elapse.new(@stat['val'])
      else
        str=@stat['val'][id]
      end
      h=hash[id]={'val'=>str}
      h['label']=@sdb[:label][id]
      set(h,'msg',id)
      set(h,'class',id)
    }
    hash
  end

  def set(hash,key,id)
    hash[key]=@stat[key][id] if @stat[key].key?(id)
  end
end

if __FILE__ == $0
  require "libinsdb"
  Msg.usage("[stat_file]") if STDIN.tty? && ARGV.size < 1
  stat=Stat.new.load
  adb=InsDb.new(stat['id']).cover_app
  puts View.new(adb,stat)
end
