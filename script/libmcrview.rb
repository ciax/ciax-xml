#!/usr/bin/ruby
require 'libmcrpar'
require 'libreclist'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Macro Man View
    class View < Varx
      def initialize(id, page, stat = RecList.new, valid_keys = [])
        super('mcr')
        @stat = type?(stat, RecList)
        @org_cmds = (@valid_keys = valid_keys).dup
        @page = type?(page, Parameter)
        # @visible content is Record
        @visible = Hashx.new
        @all_keys = []
        @ciddb = { '0' => 'user' }
        @id = id
        ___init_upd_proc
      end

      # Show Record(id = @page.current_rid) or List of them
      def to_v
        @page.current_rid ? __crnt_rec.to_v : ___list_view
      end

      def to_r
        @page.current_rid ? __crnt_rec.to_r : super
      end

      def index
        n = @page.current_idx
        if n
          rec = __crnt_rec
          opt = optlist(rec[:option]) if rec.busy? && rec.last
          "[#{n + 1}]#{opt}"
        else
          '[0]'
        end
      end

      def clean
        (keys - @all_keys).each { |id| @visible.delete(id) }
        self
      end

      private

      def ___init_upd_proc
        @upd_procs << proc do
          ___upd_valid_keys
          pids = @visible.values.map { |r| r[:pid] }
          pids.delete('0')
          @all_keys.concat(pids + @page.list).uniq!
          @all_keys.each { |id| ___upd_or_gen(id) }
          clean
        end
      end

      # Available commands in current record
      def ___upd_valid_keys
        rid = @page.current_rid
        opts = if rid
                 (__crnt_rec || {})[:option] || []
               else
                 @org_cmds
               end
        @valid_keys.replace(opts)
      end

      def ___upd_or_gen(id)
        if @visible.key?(id)
          @visible.get(id).upd
        else
          rec = @stat.get(id)
          @visible.put(id, rec)
          @ciddb[id] = rec[:cid] unless @ciddb.key?(id)
        end
      end

      def __crnt_rec
        @visible.get(@page.current_rid)
      end

      def ___list_view
        page = ['<<< ' + colorize("Active Macros [#{@id}]", 2) + ' >>>']
        @page.list.each_with_index do |id, idx|
          page << ___item_view(id, idx + 1)
        end
        page.join("\n")
      end

      def ___item_view(id, idx)
        rec = @visible[id]
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
