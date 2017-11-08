#!/usr/bin/ruby
require 'libparam'
require 'librecord'
require 'libseqlist'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Macro Man View
    class SeqView < Varx
      def initialize(id, par, stat = List.new)
        super('mcr')
        @stat = type?(stat, List)
        @par = type?(par, Parameter)
        # @list content is Record
        @list = Hashx.new
        @all_keys = []
        @ciddb = { '0' => 'user' }
        @id = id
        _init_upd_proc
      end

      def to_v
        __crnt ? __crnt.to_v : ___list
      end

      def to_r
        __crnt ? __crnt.to_r : super
      end

      def index
        n = @par.index
        if n
          opt = optlist(__crnt[:opt]) if __crnt.busy? && __crnt.last
          "[#{n + 1}]#{opt}"
        else
          '[0]'
        end
      end

      def clean
        (keys - @all_keys).each { |id| @list.delete(id) }
        self
      end

      private

      def _init_upd_proc
        @upd_procs << proc do
          pids = @list.values.map { |r| r[:pid] }
          pids.delete('0')
          @all_keys.concat(pids + @par.list).uniq!
          @all_keys.each { |id| ___upd_or_gen(id) }
          clean
        end
      end

      def ___upd_or_gen(id)
        if @list.key?(id)
          @list.get(id).upd
        else
          rec = @stat.get(id)
          @list.put(id, rec)
          @ciddb[id] = rec[:cid] unless @ciddb.key?(id)
        end
      end

      def __crnt
        @list.get(@par.current)
      end

      def ___list
        page = ['<<< ' + colorize("Active Macros [#{@id}]", 2) + ' >>>']
        @par.list.each_with_index { |id, idx| page << ___item(id, idx + 1) }
        page.join("\n")
      end

      def ___item(id, idx)
        rec = @list[id]
        title = "[#{idx}] (#{id})(by #{@ciddb[rec[:pid]]})"
        msg = "#{rec[:cid]} #{rec.step_num}"
        msg << ___result(rec)
        itemize(title, msg)
      end

      def ___result(rec)
        if rec[:status] == 'end'
          "(#{rec[:result]})"
        else
          msg = "(#{rec[:status]})"
          msg << optlist(rec[:opt]) if rec.last
          msg
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id] ..') do |_opt, args|
        par = Parameter.new.flush(args)
        puts SeqView.new('test', par).upd
      end
    end
  end
end
