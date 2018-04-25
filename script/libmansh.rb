#!/usr/bin/ruby
require 'libman'
require 'libmanview'
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
          @par = Parameter.new
          @cobj.rem.int.cfg[:parameters] = [@par]
          ___init_view
          ___init_lcmd
          ___init_post_exe
          # Set Current ID by number
          input_conv_num do |i|
            @par.sel(i)
            # nil:no command -> show record
            nil
          end
          self
        end

        private

        def ___init_view
          @view = ManView.new(@id, @par, @stat, @cobj.rem.int.valid_keys)
          # @view will be switched among Whole List or Records
          # Setting @par will switch the Record
          @cfg[:output] = @view
          @post_exe_procs << proc { @view.upd }
          @prompt_proc = proc do
            @sv_stat.to_s + @view.upd.index
          end
        end

        def ___init_lcmd
          @cobj.loc.add_page.get('cl').def_proc do
            alive = @sv_stat.upd.get(:list)
            @par.flush(alive)
            @stat.flush(alive)
          end
          @cobj.loc.add_view
        end

        def ___init_post_exe
          @post_exe_procs << proc do
            @sv_stat.get(:list).each { |id| @par.push(id) }
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
end
