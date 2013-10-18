#!/usr/bin/ruby
require "libstatus"

module CIAX
  module App
    class View < Hashx
      def initialize(adb,stat)
        @sdb=type?(adb,Db)[:status]
        @stat=type?(stat,Status)
        ['data','class','msg'].each{|key|
          stat[key]||={}
        }
      end

      def to_s
        conv
        super
      end

      private
      def conv
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
                h['msg']=@stat['msg'][id]||@stat.data[id]
              end
              set(h,'class',id)
            }
            self[k]['lines'] << hash
          }
        }
        self
      end

      def set(hash,key,id)
        hash[key]=@stat[key][id] if @stat[key].key?(id)
      end
    end

    module Print
      def self.extended(obj)
        Msg.type?(obj,View)
      end

      def to_s
        conv
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
      require "liblocdb"
      GetOpts.new('h:')
      id=ARGV.shift
      host=ARGV.shift
      stat=Status.new
      begin
        if ! STDIN.tty?
          stat.read
          id=stat['id']
          adb=Loc::Db.new.set(id)[:app]
        else
          adb=Loc::Db.new.set(id)[:app]
          id=adb['site_id']
          if host=$opt['h']
            stat.ext_http(id,host).load
          else
            stat.ext_file(id).load
          end
        end
        puts View.new(adb,stat).extend(Print)
      rescue InvalidID
        $opt.usage "(opt) [id] <(stat_file)"
      end
      exit
    end
  end
end
