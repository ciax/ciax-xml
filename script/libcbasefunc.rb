#!/usr/bin/env ruby
require 'libcbasepar'
# @cfg[:def_proc] should be Proc which is given |Entity| as param
#   returns String as message.
module CIAX
  # Command Module
  module CmdBase
    # Default Proc Setting method
    module CmdFunc
      include Msg
      attr_reader :cfg, :view_par

      # args will be destroyed
      def set_cmd(args = [], opt = {})
        id = type?(args, Array).shift
        all_keys.include?(id) ||
          noncmd_err('Nonexistent command [%s]', id) { view_dic }
        valid_keys.include?(id) ||
          cmd_err('Invalid command [%s]', id) { view_dic }
        form = get(id)
        @view_par = form.view_par
        form.set_par(args, opt)
      end

      def error
        cmd_err { view_dic }
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
        if @cfg.key?(:parameters)
          @cfg[:parameters] = ParArray.new(@cfg[:parameters])
        end
        self
      end
    end
  end
end
