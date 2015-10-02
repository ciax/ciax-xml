#!/usr/bin/ruby
require "libappsym"

# View is not used for computing, just for apperance for user.
# So the convert process (upd) will be included in to_v
# Updated at to_v.
module CIAX
  module App
    # Hash of App Groups
    class View < Upd
      def initialize(stat)
        super()
        @stat=type?(stat,Status)
        adbs=type?(@stat.dbi,Dbi)[:status]
        @group=adbs[:group]
        @index=adbs[:index].dup
        if adbs.key?(:alias)
          @group['gal']={'caption'=>'Alias',:members => adbs[:alias].keys}
          @index.update(adbs[:alias])
        end
        @stat.post_upd_procs << proc{
          verbose{"Propagate Status#upd -> upd"}
          upd
        }
        # Just additional data should be provided
        ['data','class','msg'].each{|key|
          stat[key]||={}
        }
      end

      def to_csv
        str=''
        @group.values.each{|gdb|
          cap=gdb['caption'] || next
          gdb[:members].each{|id|
            label=@index[id]['label']
            str << "#{cap},#{label},#{@stat.get(id)}\n"
          }
        }
        str
      end

      def to_r
        @stat.to_r
      end

      def to_v
        upd
        cm=Hash.new(2).update({'active'=>5,'alarm' =>1,'warn' =>3,'hide' =>0})
        lines=[]
        values.each{|v|
          cap=v['caption']
          lines << " ***"+color(cap,10)+"***" unless cap.empty?
          lines.concat v['lines'].map{|ele|
            "  "+ele.values.map{|val|
              c=cm[val['class']]+8
              '['+color(val['label'],14)+':'+color(val['msg'],c)+"]"
            }.join(' ')
          }
        }
        lines.join("\n")
      end

      private
      def upd_core
        self['gtime']={'caption'=>'','lines'=>[hash={}]}
        hash['time']={'label'=>'TIMESTAMP','msg'=>Msg.date(@stat['time'])}
        hash['elapsed']={'label'=>'ELAPSED','msg'=>Msg.elps_date(@stat['time'])}
        @group.each{|k,gdb|
          cap=gdb['caption'] || next
          self[k]={'caption' => cap,'lines'=>[]}
          col=gdb['column']||1
          gdb[:members].each_slice(col.to_i){|hline|
            hash={}
            hline.each{|id|
              h=hash[id]={'label'=>@index[id]['label']||id.upcase}
              h['msg']=@stat['msg'][id]||@stat.get(id)
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
        dbi=Ins::Db.new.get(id)
        stat.set_dbi(dbi)
        view=View.new(stat)
        stat.ext_save.ext_load if STDIN.tty?
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
