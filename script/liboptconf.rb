#!/usr/bin/env ruby
require 'libconf'
require 'libopt'
require 'libudp'

module CIAX
  # Option module
  module Opt
    # Option parser with Config
    class Conf < Get
      def initialize(ustr = '', optargs = {})
        # opt is self
        super do |opt, args|
          yield _init_cfg(opt, args)
        end
      end

      def proj
        @cfg[:proj] ||= @cfg.args.shift
      end

      # Get init_layer (default 'Wat') with require file
      def top_layer
        name = super
        require "lib#{name}dic"
        ___init_db
        ___get_mod(name)
      end

      private

      def _init_cfg(opt, args)
        @cfg = Config.new(opt: opt, args: args, proj: ___get_proj)
      end

      def ___get_proj
        return PROJ unless (host = self[:h])
        udp = Udp::Client.new(host, 54_321)
        line = j2h(udp.send('top').recv).first
        line.chomp.split(':').last
      end

      def ___init_db
        @cfg[:db] = Ins::Db.new(@cfg.proj)
        sites = @cfg[:sites] = @cfg.args
        @cfg[:db].reduce(sites) unless sites.empty?
      end

      def ___get_mod(name)
        mod = name.capitalize
        cfg_err("No #{mod} module") unless CIAX.const_defined?(mod)
        CIAX.const_get(mod)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Conf.new('', options: 'h') do |cfg|
        printf("PROJ=%s\n", cfg.get(:proj))
      end
    end
  end
end
