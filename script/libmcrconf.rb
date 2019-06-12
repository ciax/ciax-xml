#!/usr/bin/env ruby
require 'liboptconf'
require 'libmcrdb'
require 'libprompt'
require 'libwatdic'
require 'librecarc'

# CIAX_XML
module CIAX
  # Macro Layer
  module Mcr
    # Attribute for Mcr Config (Separated from Driver Config)
    class Conf < Opt::Conf
      def initialize(ustr = '', optargs = {})
        super do |cfg|
          yield(___init_cfg(cfg))
        end
      end

      private

      def ___init_cfg(cfg)
        cfg[:dbi] = Db.new.get(proj)
        cfg[:sv_stat] = ___init_prompt(proj, self[:n])
        cfg[:rec_arc] = RecArc.new
        cfg
      end

      def ___init_prompt(proj, nonstop)
        ss = Prompt.new('mcr', proj)
        # list: running macros
        ss.init_array(:list)
        # run: sites in motion
        ss.init_array(:run)
        # sid: serial ID
        ss.init_str(:sid)
        ss.init_flg(nonstop: '(nonstop)')
        ss.up(:nonstop) if nonstop
        ss
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Conf.new('[id]') do |cfg|
        puts cfg.path(cfg.args.shift)
      end
    end
  end
end
