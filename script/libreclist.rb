#!/usr/bin/ruby
require 'librecord'
require 'librecarc'

module CIAX
  # Macro Layer
  module Mcr
    # Visible Record Database
    # Need RecArc to get Parent CID
    # visible Array is Parameter[:list]
    # RecArc(Index) > RecList(Records) > Visible(IDs)
    # RecList : Server Side
    # Visible : Client Side (Parameter#list)
    class RecList < Upd
      attr_reader :rec_arc
      def initialize(id = 'mcr', visible = [])
        super()
        @id = id
        @rec_arc = RecArc.new(id)
        @visible = type?(visible, Array)
        @upd_procs << proc { values.each(&:upd) }
      end

      # delete from @records other than in ary
      def flush(ary)
        (keys - ary).each do |id|
          delete(id)
        end
        cmt
      end

      def push(record) # returns self
        id = record[:id]
        return self unless id.to_i > 0
        self[id] = record
        cmt
      end

      def ext_local
        @rec_arc.ext_local_manipulate.auto_load.refresh
        self
      end

      #### Client Methods ####
      def ext_remote(host)
        @host = host
        @rec_arc.ext_remote(host)
        self
      end

      def ext_server
        @rec_arc.clear.refresh_bg
        self
      end

      def get(id)
        type?(id, String)
        super(id) do |key|
          Record.new(key).ext_remote(@host)
        end
      end

      # Change visible list
      def get_arc(num = 1)
        rkeys = @rec_arc.upd.list.keys
        @visible.replace(rkeys.sort.last(num.to_i))
        self
      end

      # Show Index of Visible Item
      def to_v
        ___list_view
      end

      private

      def ___list_view
        page = ['<<< ' + colorize("Active Macros [#{@id}]", 2) + ' >>>']
        @visible.each_with_index do |id, idx|
          page << ___item_view(id, idx + 1)
        end
        page.join("\n")
      end

      def ___item_view(id, idx)
        rec = get(id)
        tim = Time.at(id[0..9].to_i).to_s
        title = "[#{idx}] #{id} (#{tim}) by #{___get_pcid(rec[:pid])}"
        msg = "#{rec[:cid]} #{rec.step_num}"
        msg << ___result_view(rec)
        itemize(title, msg)
      end

      def ___result_view(rec)
        if rec[:status] == 'end'
          "(#{rec[:result]})"
        else
          msg = "(#{rec[:status]})"
          msg << optlist(rec[:option]) if rec.last
          msg
        end
      end

      def ___get_pcid(pid)
        return 'user' if pid == '0'
        @rec_arc.list[pid][:cid]
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[num]') do |_opt, args|
        puts RecList.new.get_arc(args.shift).to_v
      end
    end
  end
end
