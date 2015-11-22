#!/usr/bin/ruby
require 'libmcrman'
module CIAX
  # Macro Layer
  module Mcr
    # Shell
    module Shell
      include CIAX::Shell
      # cfg should have [:jump_groups]
      def ext_shell
        super
        @par.sel
        _init_view_
        _init_lcmd_
        # Set Current ID by number
        input_conv_num do|i|
          @par.sel(i)
          nil
        end
        self
      end

      private

      def _init_view_
        @view = View.new(@id, @par, @records)
        @cfg[:output] = @view
        @post_exe_procs << proc { @view.upd }
        @prompt_proc = proc { @view.upd.index }
      end

      def _init_lcmd_
        sg = @cobj.loc.add(Dummy, caption: 'Switch Pages', color: 5)
        sg.add_item('0', 'List page')
        sg.add_item('[1-n]', 'Sequencer page')
        @cobj.loc.add_view
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('cmnlrt')
      begin
        cfg = Config.new
        cfg[:jump_groups] = []
        cfg[:dev_list] = Wat::List.new(cfg).sub_list
        Man.new(cfg).ext_shell.shell
      rescue InvalidCMD
        OPT.usage('[cmd] (par)')
      rescue InvalidID
        OPT.usage('[proj] [cmd] (par)')
      end
    end
  end
end
