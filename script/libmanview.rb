#!/usr/bin/ruby
require 'libmcrpar'
require 'libreclist'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Macro Man View
    # Switch Pages of "Record List" and "Content of Record"
    class ManView < Upd
      # RecArc:
      #     Record Archive (Remote/Local)
      # RecList < RecArc:
      #     Current Record List
      # @sv_stat[:list] < RecList:
      #     Alive Record List (Remote/Local)
      # @par[:default]:
      #     Current Record

      def initialize(sv_stat, par, rec_list = RecList.new, valid_keys = [])
        super()
        @sv_stat = type?(sv_stat, Prompt)
        @par = type?(par, Parameter)
        @rec_list = type?(rec_list, RecList)
        @org_cmds = (@valid_keys = valid_keys).dup
        # To finish up update which is removed from alive list at the end
        @alives = []
        ___init_procs
      end

      # Show Record(id = @par.current_rid) or List of them
      def to_v
        (__crnt_rec || @rec_list).to_v
      end

      def to_r
        (__crnt_rec || @rec_list).to_r
      end

      def prompt_index
        return '[0]' unless (rec = __crnt_rec)
        opt = optlist(rec[:option]) if rec.busy? && rec.last
        "[#{@par.current_idx}]#{opt}"
      end

      def get_arc(n = 1)
        @rec_list.get_arc(n.to_i)
        @par.flush(@rec_list.list.keys)
        self
      end

      def add_arc
        get_arc(@par.list.size + 1)
        self
      end

      def ext_local
        @rec_list.ext_local
        self
      end

      def ext_remote(host)
        @rec_list.ext_remote(host)
        self
      end

      private

      def ___init_procs
        @rec_list.cmt_procs << proc { |rl| @par.flush(rl.list.keys) }
        @upd_procs << proc do
          # Available commands in current record
          opts = @par.current_rid ? __crnt_opt : @org_cmds
          @valid_keys.replace(opts)
          @alives.each { |id| @rec_list.get(id) }
          @alives = @sv_stat.get(:list).dup
          @par.list
        end
      end

      def __crnt_rec
        @rec_list.ordinal(@par.current_idx)
      end

      def __crnt_opt
        (__crnt_rec || {})[:option] || []
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libmcrconf'
      ConfOpts.new('[id] ..') do |cfg, args|
        num = args.shift.to_i
        par = Parameter.new
        sv_stat = Prompt.new(cfg[:id])
        view = ManView.new(sv_stat, par).ext_local.get_arc(num)
        par.sel(args.shift.to_i)
        puts view
      end
    end
  end
end
