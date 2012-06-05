#!/usr/bin/ruby
require "libmsg"
require "libvar"
require 'libelapse'

module Status
  class Var < Var
    extend Msg::Ver
    def initialize
      Var.init_ver('Status',6)
      super('stat')
      @last={}
    end

    def set(hash) #For Watch test
      @val.update(hash)
      self
    end

    def change?(id)
      Var.msg{"Compare(#{id}) current=[#{@val[id]}] vs last=[#{@last[id]}]"}
      @val[id] != @last[id]
    end

    def update?
      change?('time')
    end

    def refresh
      Var.msg{"Status Updated"}
      @last.update(@val)
      self
    end

    def ext_save
      super
      extend Save
      self
    end
  end

  module Save
    extend Msg::Ver
    def self.extended(obj)
      init_ver(obj,6)
      Msg.type?(obj,Var).init
    end
    def init
      @lastsave=0
      self
    end
    def save(data=nil,tag=nil)
      time=@val['time'].to_f
      if time > @lastsave
        super
        @lastsave=time
        true
      else
        Save.msg{"Skip Save for #{time}"}
        false
      end
    end
  end

  class View < ExHash
    def initialize(adb,stat)
      @sdb=Msg.type?(adb,App::Db)[:status]
      @stat=Msg.type?(stat,Var)
      ['val','class','msg'].each{|key|
        stat[key]||={}
      }
    end

    def to_s
      gdb=@sdb[:group]
      gdb[:items].each{|k,v|
        cap=gdb[:caption][k] || next
        self[k]={'caption' => cap,'lines'=>[]}
        col=gdb[:column][k]||1
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

  module Print
    def self.extended(obj)
      Msg.type?(obj,View)
    end

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
end

if __FILE__ == $0
  require "libinsdb"

  Msg.getopts('rh:')
  id=ARGV.shift
  host=ARGV.shift
  stat=Status::Var.new
  begin
    if ! STDIN.tty?
      stat.load
      id=stat['id']
      adb=Ins::Db.new(id).cover_app
    else
      adb=Ins::Db.new(id).cover_app
      stat.ext_file(adb)
      if host=$opt['h']
        stat.ext_url(host).load
      else
        stat.load
      end
    end
    view=Status::View.new(adb,stat)
    view.extend(Status::Print) unless $opt['r']
    puts view
  rescue UserError
    Msg.usage "(opt) [id] <(stat_file)",*$optlist
  end
  exit
end
