#!/usr/bin/ruby
require 'librecarc'

module CIAX
  # Macro Layer
  module Mcr
    # Divided for Rubocop
    class RecView < Upd
      attr_reader :rec_arc, :list
      def initialize(rec_arc, rec_dic = Hashx.new)
        super()
        @rec_arc = type?(rec_arc, RecArc)
        # @cache in RecDic
        @rec_dic = rec_dic
        @list = []
        ___init_propagate
      end

      # Show Index of Alives Item
      def to_v
        (['<<< ' + colorize('Archive Records', 2) + ' >>>'] +
        lines).join("\n")
      end

      def tail(num)
        @list.concat(@rec_arc.tail(num)).sort!.uniq!
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

      def ___init_propagate
        upd_propagate(@rec_arc)
        cmt_propagate(@rec_arc)
        @cmt_procs << proc { ___inc_list }
      end

      def ___inc_list
        if @list.empty?
          @list << @rec_arc.list.last
        else
          max = @list.max.to_i
          @rec_arc.list.each { |i| @list << i if i.to_i > max }
          @list.sort!.uniq!
        end
      end

      def ___item_view(id, idx)
        rec = @rec_dic.get(id) || @rec_arc.get(id)
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
        puts rv.tail(args.shift.to_i)
      end
    end
  end
end
