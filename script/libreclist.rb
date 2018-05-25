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
    # Visible : Client Side
    class RecList < Upd
      def initialize(rec_arc = RecArc.new.load, visible = [])
        @rec_arc = type?(rec_arc, RecArc)
        @visible = type?(visible, Array)
        @id = @rec_arc.id
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
        record.cmt_procs << proc { rec_arc.push(record) }
        self[id] = record
        cmt
      end

      #### Client Methods ####
      def ext_http(host)
        @host = host
        self
      end

      def get(id)
        type?(id, String)
        super(id) { |key| Record.new(key).ext_http(@host, 'record') }
      end

      # Change visible list
      def get_arc(num = 1)
        @visible.replace(@rec_arc.list.keys.sort.last(num.to_i))
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
