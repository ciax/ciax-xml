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
        _set_crnt_
        @prompt_proc = proc { @view.upd.num }
        # Convert number as command
        input_conv_num { |i| _set_crnt_(i) }
        vg = @cobj.loc.add_view
        vg.add_item('0', 'List mode').def_proc { _set_crnt_ }
        vg.add_dummy('[1-n]', 'Sequencer mode')
        self
      end

      private

      # Set Current ID by number
      #  returns id (i = 1..size) or nil
      def _set_crnt_(i = nil)
        @parameter[:default] = @view.sel(i)
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
