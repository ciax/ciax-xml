#!/usr/bin/ruby
require 'libsh'
require 'libseqview'
require 'libmcrdrv'
module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man < Exe
      attr_reader :sub_list # Used for Layer module
      # cfg should have [:dev_list]
      def initialize(cfg)
        super(nil, Conf.new(cfg))
        verbose { 'Initiate Layer' }
        # id = nil -> taken by ARGV
        _init_net
        _init_cmd
        _init_stat
        _opt_mode
        @mode = 'MCR:' + @mode
      end

      def ext_shell
        @cfg[:output] = @stat
        extend(Shell).ext_shell
      end

      private

      # Initiate for all mode
      def _init_net
        @id = @cfg[:id]
        @host = @cfg[:host]
        @port = @cfg[:port]
      end

      def _init_cmd
        @cobj.add_rem.add_sys
        @cobj.rem.add_int(Int)
        @cobj.rem.add_ext(Ext)
        @cobj.rem.sys.add_item('nonstop', 'Mode')
        @cobj.rem.sys.add_item('interactive', 'Mode')
      end

      def _init_stat
        @par = @cobj.rem.int.ext_par.par
        @stat = List.new
        @sv_stat = @cfg[:sv_stat]
        @sub_list = @cfg[:dev_list]
      end

      def ext_client
        @post_exe_procs << proc do
          list = @par.list
          pre = list.size
          list.concat(@sv_stat.get(:list)).uniq!
          post = list.size
          @par.sel(post) if post > pre
        end
        super
      end

      # Initiate for driver
      def ext_driver
        super
        extend(Drv).ext_driver
      end

      alias_method :ext_test, :ext_driver
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', 'cenlrs') do |cfg|
        Man.new(cfg).ext_shell.shell
      end
    end
  end
end
