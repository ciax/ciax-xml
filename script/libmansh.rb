#!/usr/bin/ruby
require 'libsh'
require 'libman'
require 'librecdic'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man
      def _ext_local_shell
        extend(Shell).ext_local_shell
      end

      # Macro Shell
      module Shell
        include Exe::Shell
        # cfg should have [:jump_groups]
        def ext_local_shell
          super
          verbose { 'Initiate Mcr Shell' }
          __init_recview
          ___init_stat
          ___init_prompt
          ___init_conv
          ___init_recview_cmd
          ___init_rank_cmd(@cobj.loc.add_view)
          self
        end

        private

        def ___init_stat
          @view = RecDic.new(@stat, @id, @cobj.rem.int)
          @rec_view = @view.rec_view
          @opt.cl? ? @view.ext_remote(@host) : @view.ext_local
          @cfg[:output] = @view
        end

        def ___init_prompt
          # @view will be switched among Whole List or Records
          # Setting @par will switch the Record
          @prompt_proc = proc do
            str = @sv_stat.to_s + "[#{@view.current_idx}]"
            str << opt_listing((@view.current_rec || {})[:option])
          end
        end

        def ___init_recview_cmd
          page = @cobj.loc.add_page
          page.get('last').def_proc do |ent|
            @rec_view.inc(ent.par[0] || 1)
          end
          page.get('cl').def_proc do
            @rec_view.clr
          end
        end

        def ___init_rank_cmd(view)
          return unless @cobj.rem.ext
          view.add_item('dig', 'Show more Submacros').def_proc do
            @cobj.rem.ext.rankup
            @cobj.error
          end
          view.add_item('hide', 'Hide Submacros').def_proc do
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
      ConfOpts.new('[proj] [cmd] (par)', options: 'cnlr') do |cfg|
        Man.new(cfg).shell
      end
    end
  end
end
