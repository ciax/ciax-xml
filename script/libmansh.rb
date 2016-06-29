#!/usr/bin/ruby
require 'libman'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man
      # Macro Shell
      module Shell
        include Exe::Shell
        # cfg should have [:jump_groups]
        def ext_shell
          super
          @par.sel
          _init_view_
          _init_lcmd_
          # Set Current ID by number
          input_conv_num do |i|
            @par.sel(i)
            nil
          end
          self
        end

        private

        def _init_view_
          @view = SeqView.new(@id, @par, @stat)
          @cfg[:output] = @view
          @post_exe_procs << proc { @view.upd }
          @prompt_proc = proc { @sv_stat.to_s + @view.upd.index }
        end

        def _init_lcmd_
          sg = @cobj.loc.add(Cmd::Dummy, caption: 'Switch Pages', color: 5)
          sg.add_dummy('0', 'List page')
          sg.add_dummy('[1-n]', 'Sequencer page')
          sg.add_item('cl', 'Clean list', def_msg: 'CLEAN').def_proc do
            @par.flush(@sv_stat.upd.get(:list))
          end
          @cobj.loc.add_view
        end
      end

      if __FILE__ == $PROGRAM_NAME
        ConfOpts.new('[proj] [cmd] (par)', 'cnlr') do |cfg|
          Man.new(cfg).ext_shell.shell
        end
      end
    end
  end
end
