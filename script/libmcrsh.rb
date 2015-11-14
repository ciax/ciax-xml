#!/usr/bin/ruby
require 'libmcrman'

module CIAX
  module Mcr
    module Shell
      include CIAX::Shell
      # cfg should have [:jump_groups]
      def ext_shell
        super
        list_mode
        @lastsize = 0
        @prompt_proc = proc { @view.upd.num }
        # Convert as command
        input_conv_num do|i|
          _set_crnt_(i)
        end
        # Convert as parameter
        input_conv_num(@cobj.rem.int.keys) do|i|
          _set_crnt_(i)
        end
        vg = @cobj.loc.add_view
        vg.add_item('list', 'List mode').def_proc { list_mode }
        vg.add_dummy('[1-n]', 'Sequencer mode')
        self
      end

      private

      def _set_crnt_(i)
        @parameter[:default] = @view.sel(i)
        nil
      end

      def list_mode
        @parameter[:default] = nil
        ''
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
