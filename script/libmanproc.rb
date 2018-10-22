#!/usr/bin/ruby
require 'libman'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man
      def ext_local_processor
        @mode = @opt.dry? ? 'DRY' : 'PRCS'
        extend(Processor).ext_local_processor
      end

      # Macro Manager Processing Module
      module Processor
        def self.extended(obj)
          Msg.type?(obj, Man)
        end

        # Initiate for driver
        def ext_local_processor
          @rec_list.ext_save if @opt.mcr_log?
          @sv_stat.repl(:sid, '') # For server response
          @sub_list = @cobj.rem.ext.dev_list if @opt.drv?
          ___init_proc_loc
          @cobj.rem.ext_input_log
          self
        end

        def run
          ext_local_server if @opt.sv?
          @sub_list.run if @sub_list
          super
        end

        def ___init_proc_loc
          @cobj.get('interrupt').def_proc { @seq_list.interrupt }
          sys = @cobj.rem.sys
          sys.add_item('nonstop', 'Mode').def_proc { @sv_stat.up(:nonstop) }
          sys.add_item('interactive', 'Mode').def_proc { @sv_stat.dw(:nonstop) }
        end

        # Making Command List JSON file for WebApp
        def ___web_cmdlist
          verbose { 'Initiate JS Command List' }
          dbi = @cfg[:dbi]
          jl = Hashx.new(port: @port, commands: dbi.list, label: dbi.label)
          IO.write(vardir('json') + 'mcr_conf.js', 'var config = ' + jl.to_j)
        end
      end
    end
  end
end
