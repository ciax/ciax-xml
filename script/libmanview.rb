#!/usr/bin/ruby
require 'libmcrpar'
require 'libreclistview'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Macro Man View
    class ManView < Varx
      def initialize(id, page, stat = RecList.new, valid_keys = [])
        super('mcr')
        @stat = type?(stat, RecList).ext_view
        @org_cmds = (@valid_keys = valid_keys).dup
        @page = type?(page, Parameter)
        # @visible content is Record
        @visible = @stat.vis_list
        @all_keys = []
        @id = id
        ___init_upd_proc
      end

      # Show Record(id = @page.current_rid) or List of them
      def to_v
        @page.current_rid ? __crnt_rec.to_v : @stat.to_v
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
          @all_keys.each { |id| @visible.get(id).upd }
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

      def __crnt_rec
        @visible.get(@page.current_rid)
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
