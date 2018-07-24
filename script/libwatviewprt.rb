#!/usr/bin/ruby
require 'libwatview'

module CIAX
  # Watch Layer
  module Wat
    # Decorated data
    class View
      def ext_prt
        extend(Prt)
      end
      # Print event data (Put caption,symbole,etc.) from WDB
      module Prt
        def self.extend(obj)
          Msg.type?(obj, View)
        end

        def to_v
          upd
          vw = ''
          ___view_time(vw)
          vw << __itemize('Issuing', self[:exec])
          return vw if self[:stat].empty?
          ___view_cond(vw)
          vw << __itemize('Interrupt', self[:int])
          vw << __itemize('Blocked', self[:block])
        end

        def to_o
          @event.to_r
        end

        private

        def ___view_time(vw)
          vw << __itemize('Elapsed', elps_date(self[:time], now_msec))
          vw << __itemize('ActiveTime', elps_sec(*self[:act_time]))
          vw << __itemize('ToNextUpdate', elps_sec(now_msec, self[:upd_next]))
        end

        def ___view_cond(vw)
          vw << __itemize('Conditions')
          self[:stat].values.each do |i| # each event
            vw << cformat("    %:6s\t: %s\n", i[:label], __result(i[:active]))
            ___view_event(vw, i[:cond])
          end
        end

        def ___view_event(vw, cond)
          cond.each do |j|
            vw << case j[:type]
                  when 'compare'
                    ___make_cmp(j)
                  else
                    ___make_cond(j)
                  end
          end
        end

        def ___make_cmp(j)
          fmt = "      %s compare %s [%s]\n"
          inv = j[:inv] ? 'not' : ''
          cformat(fmt, __result(j[:res]), inv, j[:vals].join(', '))
        end

        def ___make_cond(j)
          fmt = "      %s %:3s  (%s: %s)\n"
          cformat(fmt, __result(j[:res]), j[:var], j[:type], ___make_exp(j))
        end

        def ___make_exp(j)
          cri = j[:cri]
          val = j[:val]
          if j[:type] == 'onchange'
            format('%s => %s', cri, val)
          else
            ope = j[:inv] ? '!' : '='
            format('/%s/ %s~ %s', cri, ope, val)
          end
        end

        def __result(res)
          colorize(res ? 'o' : 'x', res ? 2 : 1)
        end

        def __itemize(str, res = nil)
          cformat("  %:2s\t: %s\n", str, res)
        end
      end

      if __FILE__ == $PROGRAM_NAME
        require 'libinsdb'
        GetOpts.new('[site] | < event_file', options: 'r') do |_opt, args|
          event = Event.new(args.shift)
          wview = View.new(event).ext_prt
          event.ext_local_file if STDIN.tty?
          puts wview
        end
      end
    end
  end
end