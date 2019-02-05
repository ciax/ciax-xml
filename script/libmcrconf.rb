#!/usr/bin/env ruby
require 'libmcrdb'
require 'libprompt'
require 'libwatdic'
require 'librecarc'
require 'libudp'

# CIAX_XML
module CIAX
  # Macro Layer
  module Mcr
    # Mcr Attribute
    class Atrb < Hashx
      def initialize(cfg)
        super()
        proj = ___remote_proj(cfg) || (self[:proj] = cfg.args.shift)
        cfg[:db] = Ins::Db.new(proj)
        self[:dbi] = Db.new.get(proj)
        self[:sv_stat] = ___init_prompt(proj, cfg.opt[:n])
        self[:dev_dic] = Wat::Dic.new(cfg)
        self[:rec_arc] = RecArc.new
      end

      private

      def ___remote_proj(cfg)
        host = cfg.opt[:h]
        return cfg.proj unless host
        udp = Udp::Client.new('mcr', 'client', host, 54_321)
        udp.send('mcr:Server')
        ary = udp.recv.split(/\W/)
        ary[2]
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
      ConfOpts.new('[id]') do |cfg|
        puts Atrb.new(cfg).path(cfg.args)
      end
    end
  end
end
