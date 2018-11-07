#!/usr/bin/ruby
require 'libman'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Shell
    module Shell
      include Exe::Shell
      # cfg should have [:jump_groups]
      def ext_shell
        super
        ___init_view_rec
        ___init_view_list
        ___init_view_cmd
        ___init_conv
        self
      end

      private

      def ___init_view_rec
        # @stat will be switched among Whole List or Records
        # Setting @par will switch the Record
        @prompt_proc = proc do
          str = @sv_stat.to_s + "[#{@stat.current_idx}]"
          str << optlist((@stat.current_rec || {})[:option])
        end
      end

      def ___init_view_list
        page = @cobj.loc.add_page
        page.get('last').def_proc do |ent|
          @stat.get_arc(ent.par[0]).upd
        end
        page.get('cl').def_proc do
          @stat.flush.upd
        end
      end

      def ___init_view_cmd
        view = @cobj.loc.add_view
        view.get('dig').def_proc do
          @cobj.rem.ext.rankup
          @cobj.error
        end
        view.get('hide').def_proc do
          @cobj.rem.ext.rank(0)
          @cobj.error
        end
      end

      # Set Current ID by number
      def ___init_conv
        input_conv_num do |i|
          # i should be number
          @stat.sel(i)
          # nil:no command -> show record
          nil
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', options: 'cnlr') do |cfg|
        Man.new(cfg).ext_shell.shell
      end
    end
  end
end
