#!/usr/bin/ruby
require 'librecarc'

module CIAX
  # Macro Layer
  module Mcr
    # Divided for Rubocop
    class RecView < Upd
      attr_reader :rec_arc
      attr_accessor :max
      def initialize(rec_arc, rec_alive = {})
        super()
        @rec_arc = type?(rec_arc, RecArc)
        @rec_alive = rec_alive
        @max = 0
      end

      # Show Index of Alives Item
      def to_v
        lines.join("\n")
      end

      def list
        @rec_arc.list.keys.sort.last(@max).reverse
      end

      def lines
        page = []
        list.each_with_index do |id, idx|
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
          msg << optlist(rec[:option])
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
        rv.max = args.shift.to_i
        puts rv.to_v
      end
    end
  end
end
