#!/usr/bin/ruby
require 'libstatus'
require 'librerange'

module CIAX
  module Watch
    class Data < Datax
      # @ event_procs*
      attr_accessor :event_procs
      def initialize
        @ver_color=6
        super('watch')
        self['period']=300
        self['interval']=0.1
        self['astart']=now_msec
        self['aend']=now_msec
        #For Array element (@data contains only Array)
        ['active','exec','block','int'].each{|i| @data[i]||=Array.new}
        #For Hash element (another data will be stored to self)
        ['crnt','last','res'].each{|i| self[i]||={}}
        @event_procs=[]
        self
      end

      def active?
        ! @data['active'].empty?
      end

      def block?(args)
        cid=args.join(':')
        blkcmd=@data['block'].map{|ary| ary.join(':')}
        verbose("Watch","BLOCKING:#{blkcmd}") unless blkcmd.empty?
        blkcmd.any?{|blk| /#{blk}/ === cid} && Msg.cmd_err("Blocking(#{args})")
      end

      def batch_on_event
        # block parm = [priority(2),args]
        cmdary=@data['exec'].each{|args|
          @event_procs.each{|p| p.call([2,args])}
          verbose("Watch","ISSUED_AUTO:#{args}")
        }.dup
        @data['exec'].clear
        cmdary
      end

      def batch_on_interrupt
        verbose("Watch","Interrupt:#{@data['int']}")
        batch=@data['int'].dup
        @data['int'].clear
        batch
      end

      def ext_upd(adb,stat)
        extend(Upd).ext_upd(adb,stat)
      end
    end

    module Upd
      # @< (event_procs*)
      # @ wdb,val
      def self.extended(obj)
        Msg.type?(obj,Data)
      end

      def ext_upd(adb,stat)
        wdb=type?(adb,App::Db)[:watch]||{}
        @windex=wdb[:index]||{}
        @stat=type?(stat,App::Status)
        reg_procs(@stat)
        self['period']=wdb['period'].to_i if wdb.key?('period')
        self['interval']=wdb['interval'].to_f/10 if wdb.key?('interval')
        # Pick usable val
        @list=[]
        @windex.values.each{|v|
          @list|=v[:cnd].map{|i| i["var"]}
        }
        # @stat.data(all) = self['crnt'](picked) > self['last']
        # upd() => self['last']<-self['crnt']
        #       => self['crnt']<-@stat.data
        #       => check(self['crnt'] <> self['last']?)
        # Stat no changed -> clear exec, no eval
        @ctime=0
        self
      end

      def upd
        return self unless @stat['time'] > @ctime
        @ctime=@stat['time']
        sync
       @data.values.each{|a| a.clear}
        @windex.each{|id,item|
          next unless check(id,item)
          item[:act].each{|key,ary|
            @data[key.to_s].concat ary
          }
          @data['active'] << id
        }
        if !@data['active'].empty?
          if active?
            self['aend']=now_msec
          else
            self['astart']=now_msec
          end
        end
        verbose("Watch","Updated(#{@stat['time']})")
        super
      end

      def ext_file
        super(@stat['id'])
        @stat.save_procs << proc{save}
        self
      end

      def ext_logging
        logging=Logging.new('event',@stat['id'],@stat['ver'])
        @event_procs << proc{|p,args|
          logging.append({'cmd'=>args,'active'=>@data['active']})
        }
        self
      end

      private
      def sync
        @list.each{|i|
          self['last'][i]=self['crnt'][i]
          self['crnt'][i]=@stat.data[i]
        }
      end

      def check(id,item)
        return true unless cklst=item[:cnd]
        verbose("Watch","Check: <#{item['label']}>")
        rary=[]
        cklst.each{|ckitm|
          vn=ckitm['var']
          val=@stat.data[vn]
          case ckitm['type']
          when 'onchange'
            cmp=self['last'][vn]
            res=(cmp != val)
            verbose("Watch","  onChange(#{vn}): [#{cmp}] vs <#{val}> =>#{res}")
          when 'pattern'
            cmp=ckitm['val']
            res=(Regexp.new(cmp) === val)
            verbose("Watch","  Pattrn(#{vn}): [#{cmp}] vs <#{val}> =>#{res}")
          when 'range'
            cmp=ckitm['val']
            f="%.3f" % val.to_f
            res=(ReRange.new(cmp) == f)
            verbose("Watch","  Range(#{vn}): [#{cmp}] vs <#{f}>(#{val.class}) =>#{res}")
          end
          res=!res if /true|1/ === ckitm['inv']
          rary << res
        }
        self['res'][id]=rary
        rary.all?
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
    if t=$opt['t']
      watch.ext_file
      stat.str_update(t).upd.save
    end
    puts watch
  end
end
