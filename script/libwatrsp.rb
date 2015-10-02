#!/usr/bin/ruby
require 'libevent'
require 'librerange'

module CIAX
  module Wat
    module Rsp
      def self.extended(obj)
        Msg.type?(obj, Event)
      end
      # @stat.data(picked) = @data['crnt'](picked) > @data['last']
      # upd() => @data['last']<-@data['crnt']
      #       => @data['crnt']<-@stat.data(picked)
      #       => check(@data['crnt'] <> @data['last']?)
      # Stat no changed -> clear exec, no eval
      def ext_rsp(stat, sv_stat = {})
        @stat = type?(stat, App::Status)
        @sv_stat = type?(sv_stat, Hash)
        wdb = @dbi[:watch] || {}
        @windex = wdb[:index] || {}
        @interval = wdb['interval'].to_f if wdb.key?('interval')
        # Pick usable val
        @list = []
        @windex.values.each{|v|
          @list |= v[:cnd].map { |i| i['var'] }
        }
        @stat.post_upd_procs << proc{
          verbose { 'Propagate Status#upd -> upd' }
          upd
        }
        self
      end

      def queue(src, pri, batch = [])
        @last_updated = self['time'] = now_msec
        batch.each{|args|
          @data['exec'] << [src, pri, args]
        }
        post_upd
        self
      end

      private
      def upd_core
        return self unless @stat['time'] > @last_updated
        @last_updated = self['time'] = @stat['time']
        sync
        @data.values.each { |a| a.clear if Array === a }
        @windex.each{|id, item|
          next unless check(id, item)
          item[:act].each{|key, ary|
            if key == :exec
              ary.each{|args|
                @data['exec'] << ['event', 2, args]
              }
            else
              @data[key.to_s].concat(ary)
            end
          }
          @data['active'] << id
        }
        if @sv_stat['event']
          @data['act_end'] = now_msec
          if !active? && !@sv_stat['isu']
            @sv_stat.reset('event')
            @on_deact_procs.each { |p| p.call(self) }
          end
        elsif active?
          @sv_stat.set('event')
          @data['act_start'] = @data['act_end'] = @last_updated
          @on_act_procs.each { |p| p.call(self) }
        end
        verbose { "Updated(#{@stat['time']})" }
        self
      end

      def sync
        @list.each{|i|
          @data['last'][i] = @data['crnt'][i]
          @data['crnt'][i] = @stat.get(i)
        }
      end

      def check(id, item)
        return true unless (cklst = item[:cnd])
        verbose { "Check: <#{item['label']}>" }
        rary = []
        cklst.each{|ckitm|
          vn = ckitm['var']
          val = @stat.get(vn)
          case ckitm['type']
          when 'onchange'
            cri = @data['last'][vn]
            if cri
              if (tol = ckitm['tolerance'])
                res = ((cri.to_f - val.to_f).abs > tol.to_f)
                verbose { "  onChange(#{vn}): |[#{cri}]-<#{val}>| > #{tol} =>#{res.inspect}" }
              else
                res = (cri != val)
                verbose { "  onChange(#{vn}): [#{cri.inspect}] vs <#{val}> =>#{res.inspect}" }
              end
            else
              res = nil
            end
          when 'pattern'
            cri = ckitm['val']
            res = (Regexp.new(cri) === val)
            verbose { "  Pattern(#{vn}): [#{cri}] vs <#{val}> =>#{res.inspect}" }
          when 'range'
            cri = ckitm['val']
            f = '%.3f' % val.to_f
            res = (ReRange.new(cri) == f)
            verbose { "  Range(#{vn}): [#{cri}] vs <#{f}>(#{val.class}) =>#{res.inspect}" }
          end
          res = !res if /true|1/ === ckitm['inv']
          rary << res
        }
        @data['res'][id] = rary
        rary.all?
      end
    end

    if __FILE__ == $0
      require 'libinsdb'

      list = { 't' => 'test conditions[key=val,..]' }
      GetOpts.new('t:', list)
      begin
        stat = App::Status.new
        id = STDIN.tty? ? ARGV.shift : stat.read['id']
        dbi = Ins::Db.new.get(id)
        stat.set_dbi(dbi)
        stat.ext_save.ext_load if STDIN.tty?
        event = Event.new.set_dbi(dbi).ext_rsp(stat)
        if (t = $opt['t'])
          event.ext_save.ext_load
          stat.str_update(t)
        end
        stat.upd
        puts STDOUT.tty? ? event : event.to_j
      rescue InvalidID
        $opt.usage('(opt) [site] | < status_file')
      end
    end
  end
end
