#!/usr/bin/ruby
require 'libwatch'
require 'librerange'

module CIAX
  module Watch
    module Upd
      def self.extended(obj)
        Msg.type?(obj,Data)
      end

      def ext_upd(stat)
        wdb=@db[:watch]||{}
        @windex=wdb[:index]||{}
        @stat=type?(stat,App::Status)
        @stat.post_upd_procs << proc{upd}
        self['period']=wdb['period'].to_i if wdb.key?('period')
        self['interval']=wdb['interval'].to_f/10 if wdb.key?('interval')
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
            @data['aend']=now_msec
          else
            @data['astart']=now_msec
          end
        end
        verbose("Watch","Updated(#{@stat['time']})")
      ensure
        post_upd
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
          @data['last'][i]=@data['crnt'][i]
          @data['crnt'][i]=@stat.data[i]
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
            cmp=@data['last'][vn]
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
        @data['res'][id]=rary
        rary.all?
      end
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
      stat.skeleton(adb)
      stat.ext_file if STDIN.tty?
      watch=Watch::Data.new.skeleton(adb).ext_upd(stat)
      if t=$opt['t']
        watch.ext_file
        stat.str_update(t)
      end
      puts STDOUT.tty? ? watch : watch.to_j
    rescue InvalidID
      $opt.usage("(opt) [id]")
    end
  end
end
