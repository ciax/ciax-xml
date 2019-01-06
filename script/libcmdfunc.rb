#!/usr/bin/ruby
require 'libconf'
require 'libcmdpar'
# @cfg[:def_proc] should be Proc which is given |Entity| as param
#   returns String as message.
module CIAX
  # Command Module
  module CmdBase
    # Default Proc Setting method
    module CmdFunc
      include Msg
      attr_reader :cfg

      def set_cmd(args = [], opt = {})
        id, *par = type?(args, Array)
        valid_keys.include?(id) || error
        get(id).set_par(par, opt)
      end

      def error
        cmd_err(view_dic)
      end

      # Proc should return String
      def def_proc(&def_proc)
        @cfg[:def_proc] = type?(def_proc, Proc)
        self
      end

      def pars
        @cfg.get(:parameters) { ParArray.new }
      end

      # Parameters for any string
      def pars_any(n = 1, reg = '.')
        @cfg[:parameters] = ParArray.new(n, reg)
      end

      # Transform each element of @cfg[:parameter]
      #  JSON cache file ->  CDB Hash -> Parameter
      # Used in Ext Group
      def tr_pars
        ParArray.new(@cfg[:parameters]) if @cfg.key?(:parameters)
        self
      end
    end
  end
end
