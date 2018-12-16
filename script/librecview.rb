#!/usr/bin/ruby
require 'librecarc'

module CIAX
  # Macro Layer
  module Mcr
    # Divided for Rubocop
    class RecView < Upd
      def initialize(rec_arc)
        super()
        @rec_arc = type?(rec_arc, RecArc)
        @rec_arc.cmt_procs << proc { upd }
      end

      # Show Index of Alives Item
      def to_v
        ___list_view
      end

      def max(num)
        @max = num.to_i if num.to_i > 0
        self
      end

      private

      def ___list_view
        page = []
        idx = 0
        @rec_arc.list.each do |key, rec|
          page << ___item_view(key, rec, idx += 1)
          break if @max && idx >= @max
        end
        page.join("\n")
      end

      def ___item_view(id, rec, idx)
        tim = ___get_time(id)
        pcid = ___get_pcid(rec[:pid])
        title = format('[%s] %s (%s) by %s', idx, id, tim, pcid)
        itemize(title, rec[:cid].to_s + " (#{rec[:result]})")
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
        puts RecView.new(RecArc.new.ext_local.refresh).max(args.shift)
      end
    end
  end
end
