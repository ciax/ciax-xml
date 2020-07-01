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
      private

      def _init_cfg(opt, args)
        super.update(
          dbi: Db.new.get(proj),
          sv_stat: ___init_prompt,
          rec_arc: RecArc.new
        )
      end

      def ___init_prompt
        ss = Prompt.new('mcr', proj)
        # list: running macros
        ss.init_array(:list)
        # run: sites in motion
        ss.init_array(:run)
        # sid: serial ID
        ss.init_str(:sid)
        ss.init_flg(nonstop: '(nonstop)')
        ss.up(:nonstop) if nonstop?
        ss
      end
    end

    class Prompt < Prompt; end

    if $PROGRAM_NAME == __FILE__
      Conf.new('[id]') do |cfg|
        puts cfg.path(cfg.args.shift)
      end
    end
  end
end
