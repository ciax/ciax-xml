#!/usr/bin/ruby
require 'librecarc'

module CIAX
  # Macro Layer
  module Mcr
    # Divided for Rubocop
    class RecView < Upd
      attr_reader :rec_arc
      def initialize(rec_arc, &get_proc)
        super()
        @rec_arc = type?(rec_arc, RecArc)
        # @cache in RecDic
        @get_proc = get_proc || proc {}
        ___init_propagate
        cmt
      end

      # Show Index of Alives Item
      def to_v
        (['<<< ' + colorize('Archive Records', 2) + ' >>>'] +
        lines).join("\n")
      end

      def to_r
        list.extend(Enumx).to_r
      end

      def list
        rl = @rec_arc.list
        rl[rl.index(@oldest) + 1..-1].reverse
      end

      def clear
        @oldest = @rec_arc.list.last
        self
      end

      def inc(num = 1)
        rl = @rec_arc.list
        @oldest = rl[rl.index(@oldest) - num.to_i]
        self
      end

      def lines
        idx = 0
        list.map do |id|
          ___item_view(id, idx += 1)
        end
      end

      private

      def ___init_propagate
        upd_propagate(@rec_arc)
        cmt_propagate(@rec_arc)
        @cmt_procs << proc do
          clear unless @oldest
        end
      end

      def ___item_view(id, idx)
        rec = @get_proc.call(id) || @rec_arc.get(id)
        tim = ___get_time(id)
        pcid = ___get_pcid(rec[:pid])
        title = format('[%s] %s (%s) by %s', idx, id, tim, pcid)
        itemize(title, rec[:cid].to_s + ___result_view(rec))
      end

      def ___result_view(rec)
        if rec.key?(:status) && rec[:status] != 'end'
          args = rec.pick(%i(steps total_steps status)).values
          args[0] = args[0].size
          msg = format(' [%s/%s](%s)', *args)
          msg << opt_listing(rec[:option])
          msg
        else
          " (#{rec[:result]})"
        end
      end

      def ___get_time(id)
        Time.at(id[0..9].to_i).to_s
      end

      def ___get_pcid(pid)
        return 'user' if pid == '0'
        @rec_arc.get(pid)[:cid]
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[num]') do |_opts, args|
        rv = RecView.new(RecArc.new.ext_local.ext_load)
        puts rv.inc(args[0])
      end
    end
  end
end
