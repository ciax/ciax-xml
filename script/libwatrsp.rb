#!/usr/bin/ruby
require 'libevent'
require 'librerange'

module CIAX
  module Watch
    module Rsp
      def self.extended(obj)
        Msg.type?(obj,Event)
      end

      def ext_rsp(stat)
        wdb=@db[:watch]||{}
        @windex=wdb[:index]||{}
        @stat=type?(stat,App::Status)
        @stat.post_upd_procs << proc{upd}
        @period=wdb['period'].to_i if wdb.key?('period')
        @interval=wdb['interval'].to_f/10 if wdb.key?('interval')
        # Pick usable val
        @list=[]
        @windex.values.each{|v|
          @list|=v[:cnd].map{|i| i["var"]}
        }
        # @stat.data(all) = @data['crnt'](picked) > @data['last']
        # upd() => @data['last']<-@data['crnt']
        #       => @data['crnt']<-@stat.data
        #       => check(@data['crnt'] <> @data['last']?)
        # Stat no changed -> clear exec, no eval
        @ctime=0
        upd
        self
      end

      def upd
        return self unless @stat['time'] > @ctime
        @ctime=@stat['time']
        sync
        @data.values.each{|a| a.clear if Array === a}
        @windex.each{|id,item|
          next unless check(id,item)
          item[:act].each{|key,ary|
            @data[key.to_s].concat ary
          }
          @data['active'] << id
        }
        if !@data['active'].empty?
          if active?
            @data['act_end']=now_msec
          else
            @data['act_start']=now_msec
          end
        end
        verbose("Rsp","Updated(#{@stat['time']})")
        self
      ensure
        post_upd
      end

      def ext_logging
        logging=Logging.new('event',Hash[self])
        @post_upd_procs << proc{
          logging.append('cmd'=>@data['exec'],'active'=>@data['active'])
        }
        self
      end

      private
      def sync
        @list.each{|i|
          @data['last'][i]=@data['crnt'][i]
          @data['crnt'][i]=@stat.data[i]
        }
      end

      def check(id,item)
        return true unless cklst=item[:cnd]
        verbose("Rsp","Check: <#{item['label']}>")
        rary=[]
        cklst.each{|ckitm|
          vn=ckitm['var']
          val=@stat.data[vn]
          case ckitm['type']
          when 'onchange'
            cmp=@data['last'][vn]
            res=(cmp != val)
            verbose("Rsp","  onChange(#{vn}): [#{cmp}] vs <#{val}> =>#{res}")
          when 'pattern'
            cmp=ckitm['val']
            res=(Regexp.new(cmp) === val)
            verbose("Rsp","  Pattrn(#{vn}): [#{cmp}] vs <#{val}> =>#{res}")
          when 'range'
            cmp=ckitm['val']
            f="%.3f" % val.to_f
            res=(ReRange.new(cmp) == f)
            verbose("Rsp","  Range(#{vn}): [#{cmp}] vs <#{f}>(#{val.class}) =>#{res}")
          end
          res=!res if /true|1/ === ckitm['inv']
          rary << res
        }
        @data['res'][id]=rary
        rary.all?
      end
    end

    if __FILE__ == $0
      require "libsitedb"

      list={'t'=>'test conditions[key=val,..]'}
      GetOpts.new('t:',list)
      begin
        stat=App::Status.new
        id=STDIN.tty? ? ARGV.shift : stat.read['id']
        adb=Site::Db.new.set(id)[:adb]
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
