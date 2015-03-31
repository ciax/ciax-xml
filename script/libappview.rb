#!/usr/bin/ruby
require "libappsym"

# View is not used for computing, just for apperance for user.
# So the convert process (upd) will be included in to_s
# Updated at to_s.
module CIAX
  module App
    class View < Upd
      def initialize(adb,stat)
        super()
        @cls_color=2
        @pfx_color=13
        @adbs=type?(adb,Dbi)[:status]
        @stat=type?(stat,Status)
        @stat.post_upd_procs << proc{
          verbose("View","Propagate Status#upd -> App::View#upd")
          upd
        }
        # Just additional data should be provided
        ['data','class','msg'].each{|key|
          stat[key]||={}
        }
      end

      def to_csv
        str=''
        @adbs[:group].each{|k,gdb|
          cap=gdb['caption'] || next
          gdb[:members].each{|id,label|
            str << "#{cap},#{label},#{@stat.get(id)}\n"
          }
        }
        str
      end

      def to_v
        upd
        cm=Hash.new(2).update({'active'=>5,'alarm' =>1,'warn' =>3,'hide' =>0})
        lines=[]
        each{|k,v|
          cap=v['caption']
          lines << " ***"+color(cap,10)+"***" unless cap.empty?
          lines.concat v['lines'].map{|ele|
            "  "+ele.map{|id,val|
              c=cm[val['class']]+8
              '['+color(val['label'],14)+':'+color(val['msg'],c)+"]"
            }.join(' ')
          }
        }
        lines.join("\n")
      end


      private
      def upd_core
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
              h['class']=@stat['class'][id] if @stat['class'].key?(id)
            }
            self[k]['lines'] << hash
          }
        }
        self
      end
    end

    if __FILE__ == $0
      require "libinsdb"
      GetOpts.new('rc','c' => 'CSV output')
      stat=Status.new
      begin
        id=STDIN.tty? ? ARGV.shift : stat.read['id']
        adb=Ins::Db.new.set(id)
        stat.set_db(adb)
        view=View.new(adb,stat)
        stat.ext_file if STDIN.tty?
        stat.ext_sym.upd
        if $opt['c']
          puts view.to_csv
        else
          puts STDOUT.tty? ? view : view.to_j
        end
      rescue InvalidID
        $opt.usage "(opt) [site] | < status_file"
      end
      exit
    end
  end
end
