#!/usr/bin/ruby
require 'librecord'
require 'libmcrlist'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Macro Man View
    class View < Varx
      def initialize(id, page, stat = RecList.new)
        super('mcr')
        @stat = type?(stat, RecList)
        @page = type?(page, Parameter)
        # @rec_list content is Record
        @rec_list = Hashx.new
        @all_keys = []
        @ciddb = { '0' => 'user' }
        @id = id
        ___init_upd_proc
      end

      # Show Record(id = @page.current_rid) or List of them
      def to_v
        rec = __crnt_rec
        rec ? rec.to_v : ___list_view
      end

      def to_r
        rec =__crnt_rec
        rec ? rec.to_r : super
      end

      def index
        n = @page.current_idx
        if n
          if __crnt_rec.busy? && __crnt_rec.last
            opt = optlist(__crnt_rec[:option])
          end
          "[#{n + 1}]#{opt}"
        else
          '[0]'
        end
      end

      def clean
        (keys - @all_keys).each { |id| @rec_list.delete(id) }
        self
      end

      # Available commands in current record
      def valid_keys
        (__crnt_rec && __crnt_rec[:option]) || []
      end

      private

      def ___init_upd_proc
        @upd_procs << proc do
          pids = @rec_list.values.map { |r| r[:pid] }
          pids.delete('0')
          @all_keys.concat(pids + @page.list).uniq!
          @all_keys.each { |id| ___upd_or_gen(id) }
          clean
        end
      end

      def ___upd_or_gen(id)
        if @rec_list.key?(id)
          @rec_list.get(id).upd
        else
          rec = @stat.get(id)
          @rec_list.put(id, rec)
          @ciddb[id] = rec[:cid] unless @ciddb.key?(id)
        end
      end

      def __crnt_rec
        @rec_list.get(@page.current_rid)
      end

      def ___list_view
        page = ['<<< ' + colorize("Active Macros [#{@id}]", 2) + ' >>>']
        @page.list.each_with_index do |id, idx|
          page << ___item_view(id, idx + 1)
        end
        page.join("\n")
      end

      def ___item_view(id, idx)
        rec = @rec_list[id]
        title = "[#{idx}] (#{id})(by #{@ciddb[rec[:pid]]})"
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
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id] ..') do |_opt, args|
        page = Parameter.new.flush(args)
        puts View.new('test', page).upd
      end
    end
  end
end
