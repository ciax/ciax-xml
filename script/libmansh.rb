#!/usr/bin/env ruby
require 'libsh'
require 'libman'
require 'librecdic'
module CIAX
  # Macro Layer
  module Man
    # Macro Manager
    class Exe
      def _ext_shell
        extend(Shell).ext_shell
      end

      # Macro Shell
      module Shell
        include CIAX::Exe::Shell
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
          @view = Mcr::RecDic.new(@stat, @int_par)
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
          @cobj.loc.add_page
          _set_def_proc('last') { |ent| @view.inc(ent.par[0] || 1) }
          _set_def_proc('cl') { @view.flush }
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

    if $PROGRAM_NAME == __FILE__
      Conf.new('[proj] [cmd] (par)', options: 'cenlr') do |cfg|
        Exe.new(cfg)
      end.cui
    end
  end
end
