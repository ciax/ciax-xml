#!/usr/bin/ruby
require 'libmcrpar'
require 'libreclist'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Macro Man View
    # Switch Pages of "Record List" and "Content of Record"
    class ManView < Varx
      def initialize(id, par, rec_arc = RecArc.new, valid_keys = [])
        super('mcr')
        @par = type?(par, Parameter)
        @rec_list = RecList.new(type?(rec_arc, RecArc), @par.list)
        @org_cmds = (@valid_keys = valid_keys).dup
        # @records content is Record
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

      def get_arc(n = 1)
        @rec_list.get_arc(n.to_i)
        self
      end

      def add_arc
        get_arc(@par.list.size + 1)
        self
      end

      def ext_http(host)
        @rec_list.ext_http(host)
        self
      end

      private

      def ___init_upd_proc
        @upd_procs << proc do
          # Available commands in current record
          opts = @par.current_rid ? __crnt_opt : @org_cmds
          @valid_keys.replace(opts)
          @par.list.each { |id| @rec_list.get(id).upd }
        end
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
        par = Parameter.new
        view = ManView.new('test', par).get_arc(args.shift)
        par.sel(args.shift.to_i)
        puts view
      end
    end
  end
end
