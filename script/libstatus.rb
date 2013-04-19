#!/usr/bin/ruby
require "libmsg"
require "libvar"

module Status
  class Var < Var::Upd
    # @ last*
    attr_reader :last
    def initialize
      init_ver('Status',6)
      super('stat')
      @last={}
      @updated=UnixTime.now
    end

    def set(hash) #For Watch test
      self['val'].update(hash)
      self
    end

    def change?(id)
      val=self['val']
      verbose{"Compare(#{id}) current=[#{val[id]}] vs last=[#{@last[id]}]"}
      self[id] != @last[id]
    end

    def update?
      self['time'] != @updated
    end

    def refresh
      verbose{"Status Updated"}
      @last.update(self['val'])
      @updated=self['time']
      self
    end

    def ext_save
      super
      extend Save
      self
    end
  end

  module Save
    # @< (db),(base),(prefix)
    # @< (last)
    # @ lastsave
    def self.extended(obj)
      Msg.type?(obj,Save).ext_save
    end

    def ext_save
      init_ver(self,6)
      @lastsave=UnixTime.now
      self
    end

    def save(data=nil,tag=nil)
      time=self['time']
      if time > @lastsave
        super
        @lastsave=time
        true
      else
        verbose{"Skip Save for #{time}"}
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
      @sdb[:group].each{|k,gdb|
        cap=gdb['caption'] || next
        self[k]={'caption' => cap,'lines'=>[]}
        col=gdb['column']||1
        gdb[:list].each_slice(col.to_i){|ids|
          hash={}
          ids.each{|id|
            h=hash[id]={'label'=>@sdb[:label][id]||id.upcase}
            case id
            when 'elapse'
              h['msg']=Msg.elps_date(@stat['time'])
            when 'time'
              h['msg']=@stat['time'].inspect
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
  require "liblocdb"
  Msg::GetOpts.new('vh:')
  id=ARGV.shift
  host=ARGV.shift
  stat=Status::Var.new
  begin
    if ! STDIN.tty?
      stat.load
      id=stat['id']
      adb=Loc::Db.new(id)[:app]
    else
      adb=Loc::Db.new(id)[:app]
      stat.ext_file(adb['site_id'])
      if host=$opt['h']
        stat.ext_url(host).load
      else
        stat.load
      end
    end
    view=Status::View.new(adb,stat)
    view.extend(Status::Print) if $opt['v']
    puts view
  rescue UserError
    $opt.usage "(opt) [id] <(stat_file)"
  end
  exit
end
