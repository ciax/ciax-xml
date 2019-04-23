#!/usr/bin/env ruby
require 'libsh'
require 'libman'
require 'librecdic'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man
      def _ext_shell
        extend(Shell).ext_shell
      end

      # Macro Shell
      module Shell
        include Exe::Shell
        # cfg should have [:jump_groups]
        def ext_shell
          super
          verbose { 'Initiate Mcr Shell' }
          ___init_stat
          ___init_procs
          ___init_conv
          ___init_recview_cmd
          ___init_rank_cmd(@cobj.loc.add_view)
          self
        end

        private

        def ___init_stat
          @view = RecDic.new(@stat, @int_par)
          @cfg[:output] = @view
        end

        def ___init_procs
          # @view will be switched among Whole List or Records
          @prompt_proc = proc do
            opt = (@view.current_rec || {})[:option]
            str = "[#{@view.current_page}]"
            str << opt_listing(opt)
          end
        end

        def ___init_recview_cmd
          page = @cobj.loc.add_page
          page.get('last').def_proc do |ent|
            @view.inc(ent.par[0] || 1)
          end
          page.get('cl').def_proc do
            @view.flush
          end
        end

        def ___init_rank_cmd(view)
          return unless @cobj.rem.ext
          view.add_form('dig', 'Show more Submacros').def_proc do
            @cobj.rem.ext.rankup
            @cobj.error
          end
          view.add_form('hide', 'Hide Submacros').def_proc do
            @cobj.rem.ext.rank(0)
            @cobj.error
          end
        end

        # Set Current ID by number
        def ___init_conv
          # i should be number
          input_conv_num do |i|
            if i > 10_000
              i.to_s
            else
              @view.sel(i)
              nil
              # nil:no command -> show record
            end
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Conf.new('[proj] [cmd] (par)', options: 'cenlr') do |cfg|
        Man.new(cfg, Atrb.new(cfg))
      end.cui
    end
  end
end
