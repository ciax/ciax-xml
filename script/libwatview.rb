#!/usr/bin/ruby
require 'libwatrsp'

# View is not used for computing, just for apperance for user.
# So the convert process (upd_view) will be included in to_s
module CIAX
  # Watch Layer
  module Wat
    # Decorate the event data (Put caption,symbole,etc.) from WDB
    class View < Upd
      def initialize(event)
        super()
        @event = type?(event, Event)
        wdb = type?(event.dbi, Dbi)[:watch]
        init_stat(wdb || { index: [] })
        upd
      end

      def to_v
        upd
        vw = ''
        view_time(vw)
        vw << itemize('Issuing', self[:exec])
        return vw if self[:stat].empty?
        view_cond(vw)
        vw << itemize('Interrupt', self[:int])
        vw << itemize('Blocked', self[:block])
      end

      def to_o
        @event.to_r
      end

      private

      def init_stat(wdb)
        self[:stat] = Hashx.new
        wdb[:index].each do |id, evnt|
          hash = self[:stat].get(id) { Hashx.new }
          hash[:label] = evnt[:label]
          init_cond(evnt[:cnd], hash.get(:cond) { [] })
        end
        self
      end

      def init_cond(cond, m)
        cond.each do |cnd|
          h = Hash[cnd]
          case cnd[:type]
          when 'compare'
            h[:vals] = []
          when 'onchange'
          else
            h[:cri] = cnd[:val]
          end
          m << h
        end
        self
      end

      def upd_core
        self[:time] = @event[:time]
        %i(exec block int act_time upd_next).each do |id|
          self[id] = @event.get(id)
        end
        upd_stat
        self
      end

      def upd_stat
        self[:stat].each do |id, v|
          upd_cond(id, v[:cond])
          v[:active] = @event.get(:active).include?(id)
        end
        self
      end

      def upd_cond(id, cond)
        cond.each_with_index do |h, i|
          h[:res] = (@event.get(:res)[id] || [])[i]
          idx = @event.get(:crnt)
          case h[:type]
          when 'onchange'
            v = h[:var]
            h[:val] = idx[v]
            h[:cri] = @event.get(:last)[v]
          when 'compare'
            h[:vals] = h[:vars].map { |k| "#{k}:#{idx[k]}" }
          end
        end
        self
      end

      def view_time(vw)
        vw << itemize('Elapsed', elps_date(self[:time], now_msec))
        vw << itemize('ActiveTime', elps_sec(*self[:act_time]))
        vw << itemize('ToNextUpdate', elps_sec(now_msec, self[:upd_next]))
      end

      def view_cond(vw)
        vw << itemize('Conditions')
        self[:stat].values.each do |i| # each event
          vw << cformat("    %:6s\t: %s\n", i[:label], rslt(i[:active]))
          view_event(vw, i[:cond])
        end
      end

      def view_event(vw, cond)
        cond.each do |j|
          case j[:type]
          when 'compare'
            vw << _make_cmp(j)
          else
            vw << _make_cond(j)
          end
        end
      end

      def _make_cmp(j)
        fmt = "      %s compare %s [%s]\n"
        inv = j[:inv] ? 'not' : ''
        cformat(fmt, rslt(j[:res]), inv, j[:vals].join(', '))
      end

      def _make_cond(j)
        fmt = "      %s %:3s  (%s: %s)\n"
        cformat(fmt, rslt(j[:res]), j[:var], j[:type], frml(j))
      end

      def frml(j)
        cri = j[:cri]
        val = j[:val]
        if j[:type] == 'onchange'
          format('%s => %s', cri, val)
        else
          ope = j[:inv] ? '!' : '='
          format('/%s/ %s~ %s', cri, ope, val)
        end
      end

      def rslt(res)
        colorize(res ? 'o' : 'x', res ? 2 : 1)
      end

      def itemize(str, res = nil)
        cformat("  %:2s\t: %s\n", str, res)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      GetOpts.new('[site] | < event_file', 'r') do |opt|
        event = Event.new
        wview = View.new(event)
        event.ext_file if STDIN.tty?
        puts wview.vmode(opt.vmode)
      end
    end
  end
end
