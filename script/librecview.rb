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
        @oldest = @rec_arc.list.last.to_i
        # @cache in RecDic
        @get_proc = get_proc || proc {}
      end

      # Show Index of Alives Item
      def to_v
        (['<<< ' + colorize('Archive Records', 2) + ' >>>'] +
        lines).join("\n")
      end

      def list
        @rec_arc.list.select { |i| i.to_i > @oldest }
      end

      def tail(num)
        @oldest = @rec_arc.tail(num.to_i + 1).min.to_i
        self
      end

      def lines
        idx = 0
        list.map do |id|
          ___item_view(id, idx += 1)
        end
      end

      private

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
        rv = RecView.new(RecArc.new.ext_local.refresh)
        puts rv.tail(args.shift.to_i)
      end
    end
  end
end
