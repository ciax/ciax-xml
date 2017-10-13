#!/usr/bin/ruby
require 'libwatview'

module CIAX
  # Watch Layer
  module Wat
    # Print event data (Put caption,symbole,etc.) from WDB
    module Prt
      def self.extend(obj)
        Msg.type?(obj, View)
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
          vw << case j[:type]
                when 'compare'
                  _make_cmp(j)
                else
                  _make_cond(j)
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
      GetOpts.new('[site] | < event_file', options: 'r') do |_opt|
        event = Event.new
        wview = View.new(event).extend(Prt)
        event.ext_local_file if STDIN.tty?
        puts wview
      end
    end
  end
end
