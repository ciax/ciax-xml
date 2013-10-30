#!/usr/bin/ruby
require 'libwatch'

module CIAX
  module Watch
    # Put caption,symbole,etc. from DB
    class View < Hashx
      def initialize(adb,watch)
        wdb=type?(adb,App::Db)[:watch] || {:stat => []}
        @watch=type?(watch,Data)
        ['exec','block','int','astart','aend'].each{|i|
          self[i]=@watch.data[i]
        }
        self['stat']={}
        wdb[:stat].each{|k,v|
          hash=(self['stat'][k]||={})
          hash['label']=wdb[:label][k]
          m=(hash['cond']||=[])
          v.size.times{|j|
            m[j]||={}
            m[j]['type']=v[j]['type']
            m[j]['var']=v[j]['var']
            m[j]['inv']=v[j]['inv']
            if v[j]['type'] != 'onchange'
              m[j]['cmp']=v[j]['val']
            end
          }
        }
        self
      end

      def to_s
        self['stat'].each{|k,v|
          v['cond'].each_index{|i|
            h=v['cond'][i]
            id=h['var']
            h['val']=@watch['crnt'][id]
            h['res']=@watch['res']["#{k}:#{i}"]
            h['cmp']=@watch['last'][id] if h['type'] == 'onchange'
          }
          v['active']=@watch.data['active'].include?(k)
        }
        super
      end

      def ext_prt
        extend Print
      end
    end

    module Print
      def self.extended(obj)
        Msg.type?(obj,View)
      end

      def to_s
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

      private
      def conditions(str)
        self['stat'].each{|k,i|
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
    GetOpts.new('t:',list)
    id=ARGV.shift
    begin
      adb=Loc::Db.new.set(id)[:app]
    rescue InvalidID
      $opt.usage("(opt) [id]")
    end
    stat=App::Status.new.ext_file(adb['site_id']).load
    watch=Watch::Data.new.ext_upd(adb,stat).upd
    wview=Watch::View.new(adb,watch).ext_prt
    if t=$opt['t']
      watch.ext_file(adb['site_id'])
      stat.str_update(t).upd.save
    end
    puts wview
  end
end
