#!/usr/bin/ruby
require 'libevent'
require 'librerange'

module CIAX
  module Wat
    module Rsp
      def self.extended(obj)
        Msg.type?(obj,Event)
      end

      # @stat.data(picked) = @data['crnt'](picked) > @data['last']
      # upd() => @data['last']<-@data['crnt']
      #       => @data['crnt']<-@stat.data(picked)
      #       => check(@data['crnt'] <> @data['last']?)
      # Stat no changed -> clear exec, no eval
      def ext_rsp(stat)
        wdb=@db[:watch]||{}
        @windex=wdb[:index]||{}
        @stat=type?(stat,App::Status)
        @period=wdb['period'].to_i if wdb.key?('period')
        @interval=wdb['interval'].to_f if wdb.key?('interval')
        # Pick usable val
        @list=[]
        @windex.values.each{|v|
          @list|=v[:cnd].map{|i| i["var"]}
        }
        @ctime=0
        upd
        self
      end

      def queue(src,pri,batch=[])
        batch.each{|args|
          @data['exec'] << [src,pri,args]
        }
        self
      end

      def exec
        return self if @data['exec'].empty?
        @data['exec'].each{|src,pri,args|
          verbose("Executing:#{args} from [#{src}] by [#{pri}]")
          @def_proc.call(args,src,pri)
        }
        @post_exe_procs.each{|p|
          p.call(@data['exec'])
        }
        @data['exec'].clear
        sleep @interval
        self
      end

      def ext_logging
        logging=Logging.new('event',Hash[self])
        @post_exe_procs << proc{|src,pri,args|
          logging.append('src'=>src,'pri'=>pri,'cmd'=>args,'active'=>@data['active'])
        }
        self
      end

      private
      def upd_core
        return self unless @stat['time'] > @ctime
        @ctime=self['time']=@stat['time']
        sync
        act=active?
        @data.values.each{|a| a.clear if Array === a}
        @windex.each{|id,item|
          next unless check(id,item)
          item[:act].each{|key,ary|
            if key == :exec
              queue('event',2,ary)
            else
              @data[key.to_s].concat(ary)
            end
          }
          @data['active'] << id
        }
        if active?
          @data['act_start']=@ctime if !act
          @data['act_end']=now_msec
        end
        verbose("Updated(#{@stat['time']})")
        self
      end

      def sync
        @list.each{|i|
          @data['last'][i]=@data['crnt'][i]
          @data['crnt'][i]=@stat.get(i)
        }
      end

      def check(id,item)
        return true unless cklst=item[:cnd]
        verbose("Check: <#{item['label']}>")
        rary=[]
        cklst.each{|ckitm|
          vn=ckitm['var']
          val=@stat.get(vn)
          case ckitm['type']
          when 'onchange'
            cri=@data['last'][vn]
            res=(cri and cri != val)
            verbose("  onChange(#{vn}): [#{cri.inspect}] vs <#{val}> =>#{res.inspect}")
          when 'pattern'
            cri=ckitm['val']
            res=(Regexp.new(cri) === val)
            verbose("  Pattern(#{vn}): [#{cri}] vs <#{val}> =>#{res.inspect}")
          when 'range'
            cri=ckitm['val']
            f="%.3f" % val.to_f
            res=(ReRange.new(cri) == f)
            verbose("  Range(#{vn}): [#{cri}] vs <#{f}>(#{val.class}) =>#{res.inspect}")
          end
          res=!res if /true|1/ === ckitm['inv']
          rary << res
        }
        @data['res'][id]=rary
        rary.all?
      end
    end

    if __FILE__ == $0
      require "libinsdb"

      list={'t'=>'test conditions[key=val,..]'}
      GetOpts.new('t:',list)
      begin
        stat=App::Status.new
        id=STDIN.tty? ? ARGV.shift : stat.read['id']
        adb=Ins::Db.new.get(id)
        stat.set_db(adb)
        stat.ext_file if STDIN.tty?
        event=Event.new.set_db(adb).ext_rsp(stat)
        if t=$opt['t']
          event.ext_file
          stat.str_update(t)
        end
        puts STDOUT.tty? ? event : event.to_j
      rescue InvalidID
        $opt.usage("(opt) [site] | < status_file")
      end
    end
  end
end
