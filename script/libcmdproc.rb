#!/usr/bin/ruby
require 'libconf'
# @cfg[:def_proc] should be Proc which is given |Entity| as param
#   returns String as message.
module CIAX
  # Command Module
  module CmdBase
    # Default Proc Setting method
    module CmdProc
      include Msg
      attr_reader :cfg

      # Proc should return String
      def def_proc(&def_proc)
        @cfg[:def_proc] = type?(def_proc, Proc)
        self
      end

      # Param Shared in Group
      def def_par(atrb = Hashx.new)
        defpar = { type: 'str', list: [], default: nil }
        atrb.update(defpar) { |_k, s| s }
        @cfg[:parameters] = [atrb]
        self
      end

      def def_pars(n = 1)
        { parameters: Array.new(n) { Hashx.new(type: 'reg', list: ['.']) } }
      end
    end
  end
end
