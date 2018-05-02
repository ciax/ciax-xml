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

      # Proc should return String
      def def_proc(&def_proc)
        @cfg[:def_proc] = type?(def_proc, Proc)
        self
      end

      # Param Shared in Group
      def add_par(par = {})
        unless par.is_a? Parameter
          par = Parameter.new(par).update(type: 'str', list: []) { |_k, s| s }
        end
        (@cfg[:parameters] ||= []) << par
        self
      end

      def def_pars(n = 1, reg = '.')
        @cfg[:parameters] = Array.new(n) do
          Parameter.new(type: 'reg', list: [reg])
        end
        self
      end

      # Parameter setting by CDB
      def init_pars
        if @cfg.key?(:parameters)
          @cfg[:parameters].map! { |par| Parameter.new(par) }
        end
        self
      end
    end
  end
end
