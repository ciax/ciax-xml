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
        @data['astart']=now_msec
        @data['aend']=now_msec
        #For Array element
        ['active','exec','block','int'].each{|i| @data[i]||=Array.new}
        #For Hash element
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

      def issue
        # block parm = [priority(2),args]
        cmdary=@data['exec'].each{|args|
          @event_procs.each{|p| p.call([2,args])}
          verbose("Watch","ISSUED_AUTO:#{args}")
        }.dup
        @data['exec'].clear
        cmdary
      end

      def interrupt
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
        @list=['time']
        @windex.values.each{|v| @list|=v[:cnd].map{|i| i["var"]}}
        # @stat.data(all) = self['crnt'](picked) > self['last']
        # upd() => self['last']<-self['crnt']
        #       => self['crnt']<-@stat.data
        #       => check(self['crnt'] <> self['last']?)
        ['crnt','last','res'].each{|k| self[k]={}}
        # Stat no changed -> clear exec, no eval
        self
      end

      def upd
        return self unless @stat.update?
        sync
        hash={'active'=> [],'int' =>[],'exec' =>[],'block' =>[]}
        @windex.each{|id,item|
          next unless check(item)
          item[:act].each{|key,ary|
            hash[key.to_s].concat ary
          }
          hash['active'] << id
        }
        if !hash['active'].empty?
          if active?
            @data['aend']=now_msec
          else
            @data['astart']=now_msec
          end
        end
        hash.each{|k,a|
          @data[k].replace a.uniq
        }
        @stat.refresh
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
          self['crnt'][i]=@stat.data[i]
          self['last'][i]=@stat.last[i]
        }
      end

      def get_crnt(id)
        unless @list.include?(id)
          @list << id
          self['crnt'][id]=@stat.data[id]
        end
        self['crnt'][id]
      end

      def check(item)
        return true unless item[:cnd]
        verbose("Watch","Check: <#{item['label']}>")
        cklst=item[:cnd]
        rary=[]
        cklst.each{|ckitm|
          id=ckitm['var']
          val=@stat.data[id]
          case ckitm['type']
          when 'onchange'
            cmp=self['last'][id]
            res=(cmp != val)
            verbose("Watch","  onChange(#{id}): [#{cmp}] vs <#{val}> =>#{res}")
          when 'pattern'
            cmp=ckitm['val']
            res=(Regexp.new(cmp) === val)
            verbose("Watch","  Pattrn(#{id}): [#{cmp}] vs <#{val}> =>#{res}")
          when 'range'
            cmp=ckitm['val']
            f="%.3f" % val.to_f
            res=(ReRange.new(cmp) == f)
            verbose("Watch","  Range(#{id}): [#{cmp}] vs <#{f}>(#{val.class}) =>#{res}")
          end
          res=!res if /true|1/ === ckitm['inv']
          self['res']["#{id}:#{rary.size}"]=res
          rary << res
        }
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
