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

      def initialize(sv_stat, rec_list = RecList.new, valid_keys = [])
        super()
        @sv_stat = type?(sv_stat, Prompt)
        @rec_list = type?(rec_list, RecList)
        @par = type?(@rec_list.par, Parameter)
        @org_cmds = (@valid_keys = valid_keys).dup
        # To finish up update which is removed from alive list at the end
        @alives = []
        ___init_upd_procs
      end

      # Show Record(id = @par.current_rid) or List of them
      def to_v
        (@rec_list.current_rec || @rec_list).to_v
      end

      def to_r
        (@rec_list.current_rec || @rec_list).to_r
      end

      def prompt_index
        return '[0]' unless (rec = @rec_list.current_rec)
        opt = optlist(rec[:option]) if rec.busy? && rec.last
        "[#{@par.current_idx}]#{opt}"
      end

      def get_arc(n = 1)
        @rec_list.get_arc(n.to_i)
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

      def ___init_upd_procs
        @upd_procs << proc do
          # Available commands in current record
          opts = @par.current_rid ? __crnt_opt : @org_cmds
          @valid_keys.replace(opts)
          @alives.each { |id| @rec_list.get(id) }
          @alives = @sv_stat.get(:list).dup
          @par.list
        end
      end

      def __crnt_opt
        (@rec_list.current_rec || {})[:option] || []
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libmcrconf'
      ConfOpts.new('[id] ..') do |cfg, args|
        num = args.shift.to_i
        sv_stat = Prompt.new(cfg[:id])
        view = ManView.new(sv_stat).ext_local.get_arc(num)
        puts view
      end
    end
  end
end
