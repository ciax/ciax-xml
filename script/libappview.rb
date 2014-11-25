#!/usr/bin/ruby
require "libappsym"

# View is not used for computing, just for apperance for user.
# So the convert process can be included in to_s
# Updated at to_s.
module CIAX
  module App
    class View < Hashx
      def initialize(adb,stat)
        @adbs=type?(adb,Db)[:status]
        @stat=type?(stat,Status)
        @stat.post_upd_procs << proc{conv}
        # Just additional data should be provided
        ['data','class','msg'].each{|key|
          stat[key]||={}
        }
      end

      def ext_prt
        extend Print
      end

      private
      def conv
        @adbs[:group].each{|k,gdb|
          cap=gdb['caption'] || next
          self[k]={'caption' => cap,'lines'=>[]}
          col=gdb['column']||1
          gdb[:members].each_slice(col.to_i){|hline|
            hash={}
            hline.each{|id,label|
              h=hash[id]={'label'=>label||id.upcase}
              case id
              when 'elapse'
                h['msg']=Msg.elps_date(@stat['time'])
              when 'time'
                h['msg']=Msg.date(@stat['time'])
              else
                h['msg']=@stat['msg'][id]||@stat.get(id)
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
          lines.concat v['lines'].map{|ele|
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
      require "libsitedb"
      GetOpts.new('r')
      stat=Status.new
      begin
        id=STDIN.tty? ? ARGV.shift : stat.read['id']
        adb=Site::Db.new.set(id)[:adb]
        stat.set_db(adb)
        view=View.new(adb,stat)
        stat.ext_file if STDIN.tty?
        stat.ext_sym.upd
        view.ext_prt unless $opt['r']
        puts STDOUT.tty? ? view : view.to_j
      rescue InvalidID
        $opt.usage "(opt) [site] | < status_file"
      end
      exit
    end
  end
end
