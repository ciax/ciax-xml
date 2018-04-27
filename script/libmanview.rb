#!/usr/bin/ruby
require 'libmcrpar'
require 'libreclistview'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Macro Man View
    class ManView < Varx
      def initialize(id, page, rec_list = RecList.new, valid_keys = [])
        super('mcr')
        @par = type?(page, Parameter)
        @rec_list = type?(rec_list, RecList).ext_view(@par.list)
        @org_cmds = (@valid_keys = valid_keys).dup
        # @records content is Record
        @all_keys = []
        @id = id
        ___init_upd_proc
      end

      # Show Record(id = @par.current_rid) or List of them
      def to_v
        @par.current_rid ? __crnt_rec.to_v : @rec_list.to_v
      end

      def to_r
        @par.current_rid ? __crnt_rec.to_r : super
      end

      def index
        n = @par.current_idx
        return '[0]' unless n
        rec = __crnt_rec
        opt = optlist(rec[:option]) if rec.busy? && rec.last
        "[#{n + 1}]#{opt}"
      end

      def clean
        (keys - @all_keys).each { |id| @rec_list.delete(id) }
        self
      end

      private

      def ___init_upd_proc
        @upd_procs << proc do
          ___upd_valid_keys
          # Leave parent of alive process
          pids = @rec_list.values.map { |r| r[:pid] }
          pids.delete('0')
          @all_keys.concat(pids + @par.list).uniq!
          @all_keys.each { |id| @rec_list.get(id).upd }
          clean
        end
      end

      # Available commands in current record
      def ___upd_valid_keys
        opts = @par.current_rid ? __crnt_opt : @org_cmds
        @valid_keys.replace(opts)
      end

      def __crnt_rec
        @rec_list.get(@par.current_rid)
      end

      def __crnt_opt
        (__crnt_rec || {})[:option] || []
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id] ..') do |_opt, args|
        page = Parameter.new.flush(args)
        puts ManView.new('test', page).upd
      end
    end
  end
end
