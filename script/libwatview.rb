#!/usr/bin/ruby
require 'libwatch'

module CIAX
  module Watch
    # Decorate the watch data (Put caption,symbole,etc.) from WDB
    class View < Hashx
      def initialize(adb,watch)
        wdb=type?(adb,App::Db)[:watch]||{}
        @watch=type?(watch,Data)
        ['exec','block','int','astart','aend'].each{|id|
          self[id]=@watch.data[id]
        }
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
        self['stat'].each{|id,v|
          v['cond'].each_index{|i|
            h=v['cond'][i]
            var=h['var']
            h['val']=@watch['crnt'][var]
            h['res']=@watch['res'][id][i]
            h['cmp']=@watch['last'][var] if h['type'] == 'onchange'
          }
          v['active']=@watch.data['active'].include?(id)
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
        return '' if self['stat'].empty?
        super
        atime=Msg.elps_sec(@watch.data['astart'],@watch.data['aend'])
        str="  "+Msg.color("ActiveTime",2)+"\t: #{atime}\n"
        str << "  "+Msg.color("Issuing",2)+"\t: #{self['exec']}\n"
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
            str << "!" if j['inv']
            str << "(#{j['type']}: "
            if j['type'] == 'onchange'
              str << "#{j['cmp']} => #{j['val']}"
            else
              str << "/#{j['cmp']}/ =~ #{j['val']}"
            end
            str << ")\n"
          }
        }
      end

      def show_res(res,t=nil,f=nil)
        res ? Msg.color(t||res,2) : Msg.color(f||res,1)
      end
    end
  end

  if __FILE__ == $0
    require "liblocdb"

    list={}
    list['t']='test conditions[key=val,..]'
    GetOpts.new('rt:',list)
    id=ARGV.shift
    begin
      adb=Loc::Db.new.set(id)[:app]
    rescue InvalidID
      $opt.usage("(opt) [id]")
    end
    stat=App::Status.new.ext_file(adb['site_id']).load
    watch=Watch::Data.new.ext_upd(adb,stat).upd
    wview=Watch::View.new(adb,watch)
    wview.ext_prt unless $opt['r']
    if t=$opt['t']
      watch.ext_file
      stat.str_update(t).upd.save
    end
    puts wview
  end
end
