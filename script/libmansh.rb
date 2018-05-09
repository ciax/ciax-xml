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
          @cobj.rem.int.add_par(@par)
          ___init_view
          ___init_lcmd
          ___init_post_exe
          ___init_conv
          self
        end

        private

        def ___init_view
          @view = ManView.new(@id, @par, @stat, @cobj.rem.int.valid_keys)
          # @view will be switched among Whole List or Records
          # Setting @par will switch the Record
          @cfg[:output] = @view
          @prompt_proc = proc do
            @sv_stat.to_s + @view.upd.index
          end
        end

        def ___init_lcmd
          page = @cobj.loc.add_page
          page.get('last').def_proc do |ent|
            @view.get_arc(ent.par[0])
          end
          page.get('cl').def_proc do
            @par.flush(@sv_stat.upd.get(:list))
          end
          @cobj.loc.add_view
        end

        def ___init_post_exe
          @post_exe_procs << proc do
            @sv_stat.get(:list).each { |id| @par.push(id) }
            @view.upd
          end
        end

        # Set Current ID by number
        def ___init_conv
          input_conv_num do |i|
            # i should be number
            @par.sel(i)
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
end
