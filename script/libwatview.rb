#!/usr/bin/ruby
require 'libwatrsp'

# View is not used for computing, just for apperance for user. So the convert process can be included in to_s
module CIAX
  module Wat
    # Decorate the event data (Put caption,symbole,etc.) from WDB
    class View < Hashx
      def initialize(adb,watch)
        wdb=type?(adb,App::Db)[:watch]||{:index =>[]}
        @event=type?(watch,Event)
        self['stat']={}
        wdb[:index].each{|id,evnt|
          hash=(self['stat'][id]||={})
          hash['label']=evnt['label']
          m=(hash['cond']||=[])
          evnt[:cnd].each{|cnd|
            m << Hash[cnd]
            if cnd['type'] != 'onchange'
              m.last['cmp']=cnd['val']
            end
          }
        }
        self
      end

      def to_s
        conv
        super
      end

      def ext_prt
        extend Print
      end

      private
      def conv
        ['exec','block','int','act_start','act_end','upd_next'].each{|id|
          self[id]=@event.data[id]
        }
        self['stat'].each{|id,v|
          v['cond'].each_index{|i|
            h=v['cond'][i]
            var=h['var']
            h['val']=@event.data['crnt'][var]
            h['res']=@event.data['res'][id][i]
            h['cmp']=@event.data['last'][var] if h['type'] == 'onchange'
          }
          v['active']=@event.data['active'].include?(id)
        }
      end
    end

    module Print
      def self.extended(obj)
        Msg.type?(obj,View)
      end

      def to_s
        conv
      end

      private
      def conv
        super
        tonext=Msg.elps_sec(now_msec,self['upd_next'])
        atime=Msg.elps_sec(self['act_start'],self['act_end'])
        str=""
        str << "  "+Msg.color("ToNextUpdate",2)+"\t: #{tonext}\n"
        str << "  "+Msg.color("ActiveTime",2)+"\t: #{atime}\n"
        str << "  "+Msg.color("Issuing",2)+"\t: #{self['exec']}\n"
        return str if self['stat'].empty?
        str << "  "+Msg.color("Conditions",2)+"\t:\n"
        conditions(str)
        str << "  "+Msg.color("Interrupt",2)+"\t: #{self['int']}\n"
        str << "  "+Msg.color("Blocked",2)+"\t: #{self['block']}\n"
      end

      def conditions(str)
        self['stat'].each{|id,i|
          str << "    "+Msg.color(i['label'],6)+"\t: "
          str << show_res(i['active'])+"\n"
          i['cond'].each{|j|
            str << "      "+show_res(j['res'],'o','x')+' '
            str << Msg.color(j['var'],3)
            str << "  "
            ope=j['inv'] ? "!~" : "=~"
            str << "(#{j['type']}: "
            if j['type'] == 'onchange'
              str << "#{j['cmp']} => #{j['val']}"
            else
              str << "/#{j['cmp']}/ #{ope} #{j['val']}"
            end
            str << ")\n"
          }
        }
      end

      def show_res(res,t=nil,f=nil)
        res ? Msg.color(t||res,2) : Msg.color(f||res,1)
      end
    end

    if __FILE__ == $0
      require "libsitedb"
      GetOpts.new('r')
      event=Event.new
      begin
        id=STDIN.tty? ? ARGV.shift : event.read['id']
        adb=Site::Db.new.set(id)[:adb]
        event.set_db(adb)
        wview=View.new(adb,event)
        event.ext_file if STDIN.tty?
        wview.ext_prt unless $opt['r']
        puts STDOUT.tty? ? wview : wview.to_j
      rescue InvalidID
        $opt.usage("(opt) [site] | < event_file")
      end
    end
  end
end
