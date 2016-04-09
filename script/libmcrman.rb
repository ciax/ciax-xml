#!/usr/bin/ruby
require 'libsh'
require 'libmcrview'
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
        verbose { 'Initialize Layer' }
        # id = nil -> taken by ARGV
        _init_net
        _init_cmd
        _init_stat
        _init_dev
        _opt_mode
        @mode = 'MCR:' + @mode
      end

      def ext_shell
        @cfg[:output] = @stat
        extend(Shell).ext_shell
      end

      private

      # Initialize for all mode
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
        _init_proc_post_exe
      end

      def _init_proc_post_exe
        @post_exe_procs << proc do
          (@sv_stat.get(:list) - @par.list).each { |id| @par.add(id) }
        end
      end

      def _init_dev
        @cfg[:sites].each { |site| @cfg[:dev_list].get(site) }
      end

      # Initialize for driver
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
