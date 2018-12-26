#!/usr/bin/ruby
require 'librecarc'

module CIAX
  # Macro Layer
  module Mcr
    # Divided for Rubocop
    class RecView < Upd
      attr_reader :rec_arc, :list
      def initialize(rec_arc, rec_alive = {})
        super()
        @rec_arc = type?(rec_arc, RecArc)
        @rec_alive = rec_alive
        clr
      end

      # Show Index of Alives Item
      def to_v
        (['<<< ' + colorize('Archive Records', 2) + ' >>>'] +
        lines).join("\n")
      end

      def last(num)
        @list.concat(@rec_arc.last(num)).sort!.uniq!
        self
      end

      def inc(num = 1)
        last(@list.size + num.to_i)
      end

      def clr
        @list = @rec_alive.keys
        self
      end

      def lines
        page = []
        @list.each_with_index do |id, idx|
          page << ___item_view(id, idx + 1)
        end
        page
      end

      private

      def ___item_view(id, idx)
        rec = @rec_alive[id] || @rec_arc.get(id)
        tim = ___get_time(id)
        pcid = ___get_pcid(rec[:pid])
        title = format('[%s] %s (%s) by %s', idx, id, tim, pcid)
        itemize(title, rec[:cid].to_s + ___result_view(rec))
      end

      def ___result_view(rec)
        if rec.key?(:status) && rec[:status] != 'end'
          args = rec.pick(%i(steps total_steps status)).values
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
        puts rv.last(args.shift.to_i)
      end
    end
  end
end