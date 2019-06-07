#!/usr/bin/env ruby
require 'libconf'
require 'libopt'
module CIAX
  # Option module
  module Opt
    # Option parser with Config
    class Conf < Get
      def initialize(ustr = '', optargs = {})
        super do |opt, args|
          @cfg = Config.new(opt: opt, args: args, proj: PROJ)
          yield(@cfg)
        end
      end

      # Get init_layer (default 'Wat') with require file
      def top_layer
        key = __make_exopt(%i(m x w a f)) || :w
        name = @optdb.layers[key]
        require "lib#{name}dic"
        ___init_db
        ___get_mod(name)
      end

      private

      def ___init_db
        @cfg[:db] = Ins::Db.new(@cfg.proj)
        @cfg[:sites] = @cfg.args
      end

      def ___get_mod(name)
        mod = name.capitalize
        cfg_err("No #{mod} module") unless CIAX.const_defined?(mod)
        CIAX.const_get(mod)
      end
    end
  end
end
