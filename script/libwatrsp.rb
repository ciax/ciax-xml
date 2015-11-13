#!/usr/bin/ruby
require 'libevent'
require 'librerange'

module CIAX
  # Watch Layer
  module Wat
    # Watch Response Module
    module Rsp
      def self.extended(obj)
        Msg.type?(obj, Event)
      end

      # @stat.data(picked) = @data['crnt'](picked) > @data['last']
      # upd() => @data['last']<-@data['crnt']
      #       => @data['crnt']<-@stat.data(picked)
      #       => check(@data['crnt'] <> @data['last']?)
      # Stat no changed -> clear exec, no eval
      def ext_rsp(stat, sv_stat = nil)
        @stat = type?(stat, App::Status)
        @sv_stat = type?(sv_stat || Prompt.new('site', self['id']), Prompt)
        wdb = @dbi[:watch] || {}
        @windex = wdb[:index] || {}
        @interval = wdb['interval'].to_f if wdb.key?('interval')
        # Pick usable val
        @list = []
        @windex.values.each do|v|
          @list |= v[:cnd].map { |i| i['var'] }
        end
        @pre_upd_procs << proc { self['time'] = @stat['time'] }
        @stat.post_upd_procs << proc do
          verbose { 'Propagate Status#upd -> Event#upd' }
          upd
        end
        init_auto(wdb)
        self
      end

      def queue(src, pri, batch = [])
        @last_updated = self['time']
        batch.each do|args|
          @data['exec'] << [src, pri, args]
        end
        self
      end

      def auto_exec
        return self unless @data['exec'].empty?
        verbose { format('Auto Update(%s, %s)', self['time'], @regexe) }
        begin
          queue('auto', 3, @regexe)
        rescue InvalidID
          errmsg
        rescue
          warning $ERROR_INFO
        end
        self
      end

      private

      # Initialize for Auto Update
      def init_auto(wdb)
        reg = wdb[:regular] || {}
        per = reg['period'].to_i
        @period = per > 1 ? per : 300
        @regexe = reg[:exec] || [['upd']]
        verbose do
          format('Auto Update Initialize: Period = %s sec, Command = %s)',
                 @period, @regexe)
        end
        self
      end

      # @data['active'] : Array of event ids which meet criteria
      # @data['exec'] : Command queue which contains commands issued as event
      # @data['block'] : Array of commands (units) which are blocked during busy
      # @data['int'] : List of interrupt commands which is effectie during busy
      def upd_core
        return self unless @stat['time'] > @last_updated
        @last_updated = self['time']
        sync
        @data.values.each { |a| a.clear if a.is_a? Array }
        @windex.each do|id, item|
          next unless check(id, item)
          item[:act].each do|key, ary|
            if key == :exec
              ary.each do|args|
                @data['exec'] << ['event', 2, args]
              end
            else
              @data[key.to_s].concat(ary)
            end
          end
          @data['active'] << id
        end
        upd_event
        self
      end

      # @sv_stat['busy'] is internal var

      ## Timing chart in active mode
      # isu   :__--__--__--==__--___
      # actv  :___--------__----____
      # busy :_____---------------__

      ## Trigger Table
      # isu | actv| busy| action
      #  o  |  o  |  o  |  -
      #  o  |  x  |  o  |  -
      #  o  |  o  |  x  |  up
      #  o  |  x  |  x  |  -
      #  x  |  o  |  o  |  -
      #  x  |  x  |  o  | down
      #  x  |  o  |  x  |  up
      #  x  |  x  |  x  |  -

      def upd_event
        if @sv_stat['event']
          if !active? && !@sv_stat['isu']
            @sv_stat.reset('event')
            @on_deact_procs.each { |p| p.call(self) }
          end
        elsif active?
          @sv_stat.set('event')
          @data['act_start'] = @data['act_end'] = @last_updated
          @on_act_procs.each { |p| p.call(self) }
        end
        self
      end

      def sync
        @list.each do|i|
          @data['last'][i] = @data['crnt'][i]
          @data['crnt'][i] = @stat.get(i)
        end
      end

      def check(id, item)
        return true unless (cklst = item[:cnd])
        verbose { "Check: <#{item['label']}>" }
        rary = []
        cklst.each do|ckitm|
          vn = ckitm['var']
          val = @stat.get(vn)
          case ckitm['type']
          when 'onchange'
            cri = @data['last'][vn]
            if cri
              if (tol = ckitm['tolerance'])
                res = ((cri.to_f - val.to_f).abs > tol.to_f)
                verbose do
                  format('  onChange(%s): |[%s]-<%s>| > %s =>%s',
                         vn, cri, val, tol, res.inspect)
                end
              else
                res = (cri != val)
                verbose do
                  format('  onChange(%s): [%s] vs <%s> =>%s',
                         vn, cri.inspect, val, res.inspect)
                end
              end
            else
              res = nil
            end
          when 'pattern'
            cri = ckitm['val']
            res = Regexp.new(cri).match(val)
            verbose do
              format('  Pattern(%s): [%s] vs <%s> =>%s',
                     vn, cri, val, res.inspect)
            end
          when 'range'
            cri = ckitm['val']
            f = format('%.3f', val.to_f)
            res = (ReRange.new(cri) == f)
            verbose do
              format('  Range(%s): [%s] vs <%s>(%s) =>%s',
                     vn, cri, f, val.class, res.inspect)
            end
          end
          res = !res if /true|1/ =~ ckitm['inv']
          rary << res
        end
        @data['res'][id] = rary
        rary.all?
      end
    end

    # Add extend method in Event
    class Event
      def ext_rsp(stat, sv_stat = nil)
        extend(Wat::Rsp).ext_rsp(stat, sv_stat)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'

      list = { 't:' => 'test conditions[key=val,..]' }
      OPT.parse('', list)
      begin
        stat = App::Status.new
        id = STDIN.tty? ? ARGV.shift : stat.read['id']
        dbi = Ins::Db.new.get(id)
        stat.setdbi(dbi)
        stat.ext_file.load if STDIN.tty?
        event = Event.new.setdbi(dbi).ext_rsp(stat)
        if (t = OPT['t'])
          stat.str_update(t)
        end
        puts STDOUT.tty? ? event : event.to_j
      rescue InvalidID
        OPT.usage('(opt) [site] | < status_file')
      end
    end
  end
end
