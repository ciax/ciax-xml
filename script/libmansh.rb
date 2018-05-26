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
          ___init_view_rec
          ___init_view_list
          ___init_view_cmd
          ___init_post_exe
          ___init_conv
          self
        end

        private

        def ___init_view_rec
          # @stat will be switched among Whole List or Records
          # Setting @par will switch the Record
          @cfg[:output] = @stat
          @prompt_proc = proc do
            @sv_stat.to_s + @stat.upd.index
          end
        end

        def ___init_view_list
          page = @cobj.loc.add_page
          page.get('last').def_proc do |ent|
            n = ent.par[0]
            n ? @stat.get_arc(n.to_i) : @stat.add_arc
          end
          page.get('cl').def_proc do
            @par.flush(@sv_stat.upd.get(:list))
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

        def ___init_post_exe
          @post_exe_procs << proc do
            @sv_stat.get(:list).each { |id| @par.push(id) }
            @stat.upd
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
