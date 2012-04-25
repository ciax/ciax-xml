#!/usr/bin/ruby
require 'libstat'
require 'libelapse'

class View < ExHash
  def initialize(adb,stat)
    @sdb=Msg.type?(adb,AppDb)[:status]
    @stat=Msg.type?(stat,Stat)
    ['val','class','msg'].each{|key|
      stat[key]||={}
    }
  end

  def to_s
    @sdb[:group].each{|k,v|
      cap=@sdb[:caption][k] || next
      self[k]={'caption' => cap,'lines'=>[]}
      col=@sdb[:column][k]||1
      v.each_slice(col.to_i){|ids|
        hash={}
        ids.each{|id|
          h=hash[id]={'label'=>@sdb[:label][id]||id.upcase}
          case id
          when 'elapse'
            h['msg']=Elapse.new(@stat.val)
          else
            h['msg']=@stat['msg'][id]||@stat.get(id)
          end
          set(h,'class',id)
        }
        self[k]['lines'] << hash
      }
    }
    super
  end

  private
  def set(hash,key,id)
    hash[key]=@stat[key][id] if @stat[key].key?(id)
  end
end

module View::Print
  def to_s
    super
    cm=Hash.new(2).update({'active'=>5,'alarm' =>1,'warn' =>3,'hide' =>0})
    lines=[]
    each{|k,v|
      cap=v['caption']
      lines << " ***"+color(2,cap)+"***" unless cap.empty?
      lines+=v['lines'].map{|ele|
        "  "+ele.map{|id,val|
          c=cm[val['class']]
          '['+color(6,val['label'])+':'+color(c,val['msg'])+"]"
        }.join(' ')
      }
    }
    lines.join("\n")
  end

  private
  def color(c,msg)
    "\e[1;3#{c}m#{msg}\e[0m"
  end
end

if __FILE__ == $0
  require "optparse"
  require "libinsdb"
  opt=ARGV.getopts('r')
  Msg.usage("(-r) [stat_file]") if STDIN.tty? && ARGV.size < 1
  stat=Stat.new.load
  adb=InsDb.new(stat['id']).cover_app
  view=View.new(adb,stat)
  view.extend(View::Print) unless opt['r']
  puts view
end
