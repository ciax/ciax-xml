#!/usr/bin/env ruby
require 'librecarc'

module CIAX
  # Macro Layer
  module Mcr
    # Record View (Front Page)
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
        title = key?(:default) ? 'Active Macros' : 'Archive Records'
        title << "(#{@rec_arc.host})" if @rec_arc.host
        ___mk_view(title)
      end

      def to_r
        list.extend(Enumx).to_r
      end

      def list
        rl = @rec_arc.list
        rl[rl.index(@oldest) + 1..-1]
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

      def chk_def(list)
        delete(:default) if key?(:default) && !list.include?(self[:default])
        self
      end

      def put_def(id)
        self[:default] = id
        self
      end

      private

      def ___mk_view(title)
        idx = 0
        line = ['<<< ' + colorize(title, 2) + ' >>>']
        line << list.map do |id|
          ___item_view(id, idx += 1, self[:default] == id ? '*' : ' ')
        end
        line.join("\n")
      end

      def ___init_propagate
        propagation(@rec_arc)
        @cmt_procs.append(self, :rec_view) do
          clear unless @oldest
        end
      end

      def ___item_view(id, idx, pfx = nil)
        rec = @get_proc.call(id) || @rec_arc.get(id)
        tim = ___get_time(id)
        pcid = ___get_pcid(rec[:pid])
        title = format('%s[%s] %s (%s) by %s', pfx, idx, id, tim, pcid)
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
      GetOpts.new('[num]', options: 'chr') do |opts, args|
        Msg.args_err if args.empty?
        ra = RecArc.new.mode(opts.host)
        puts RecView.new(ra).inc(args[0])
      end
    end
  end
end
