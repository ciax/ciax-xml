#!/usr/bin/ruby
require "libmsg"
require "libdata"

module CIAX
  module Status
    class Data < Data
      # @ last*
      attr_reader :last
      def initialize
        @ver_color=6
        super('stat')
        @last={}
        @updated=UnixTime.now
        ext_upd
      end

      def set(hash) #For Watch test
        self['val'].update(hash)
        upd
      end

      def change?(id)
        val=self['val']
        verbose("Status","Compare(#{id}) current=[#{val[id]}] vs last=[#{@last[id]}]")
        self[id] != @last[id]
      end

      def update?
        self['time'] > @updated
      end

      def refresh
        verbose("Status","Status Updated")
        @last.update(self['val'])
        @updated=self['time']
        self
      end

      def ext_save
        super
        extend(Save).ext_save
        self
      end
    end

    module Save
      # @< (db),(base),(prefix)
      # @< (last)
      # @ lastsave
      def self.extended(obj)
        Msg.type?(obj,Save)
      end

      def ext_save
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
          verbose("Status","Skip Save for #{time}")
          false
        end
      end
    end

    class View < ExHash
      def initialize(adb,stat)
        @sdb=type?(adb,App::Db)[:status]
        @stat=type?(stat,Data)
        ['val','class','msg'].each{|key|
          stat[key]||={}
        }
      end

      def to_s
        @sdb[:group].each{|k,gdb|
          cap=gdb['caption'] || next
          self[k]={'caption' => cap,'lines'=>[]}
          col=gdb['column']||1
          gdb[:members].each_slice(col.to_i){|ids|
            hash={}
            ids.each{|id|
              h=hash[id]={'label'=>@sdb[:label][id]||id.upcase}
              case id
              when 'elapse'
                h['msg']=Msg.elps_date(@stat['time'])
              when 'time'
                h['msg']=@stat['time'].inspect
              else
                h['msg']=@stat['msg'][id]||@stat['val'][id]
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
    GetOpts.new('vh:')
    id=ARGV.shift
    host=ARGV.shift
    stat=Status::Data.new
    begin
      if ! STDIN.tty?
        stat.load
        id=stat['id']
        adb=Loc::Db.new.set(id)[:app]
      else
        adb=Loc::Db.new.set(id)[:app]
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
    rescue InvalidID
      $opt.usage "(opt) [id] <(stat_file)"
    end
    exit
  end
end
