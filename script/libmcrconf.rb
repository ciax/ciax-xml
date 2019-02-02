#!/usr/bin/env ruby
require 'libmcrdb'
require 'libprompt'
require 'libwatdic'
require 'librecarc'

# CIAX_XML
module CIAX
  # Macro Layer
  module Mcr
    # Mcr Attribute
    class Atrb < Hashx
      def initialize(cfg)
        super()
        proj = cfg.proj
        self[:dbi] = Db.new.get(proj)
        self[:sv_stat] = ___init_prompt(proj, cfg.opt[:n])
        self[:dev_dic] = Wat::Dic.new(cfg)
        self[:rec_arc] = RecArc.new
      end

      private

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
  end
end
