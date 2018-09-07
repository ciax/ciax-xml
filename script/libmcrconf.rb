#!/usr/bin/ruby
require 'libprompt'
require 'librecarc'
require 'libmcrdb'
require 'libhexlist' # deprecated

module CIAX
  # Macro Layer
  module Mcr
    # Mcr Common Parameters across all the layers
    # Upper Conf should have: :option, :jump_groups, :jump_layer
    # Mcr::Conf includes:
    # :layer_type, :db, :command, :version, :sites, :dev_list, :sv_stat
    # :host, :port
    class ConfOpts < GetOpts
      def initialize(ustr = '', optargs = {})
        super do |opt, args|
          cfg = Config.new(opt: opt, jump_groups: [], args: args)
          verbose { 'Initiate Mcr Conf (option:' + keys.join + ')' }
          ___init_db(cfg)
          yield(cfg, args)
        end
      end

      private

      def ___init_db(cfg)
        db = Db.new
        cfg.update(layer_type: 'mcr', db: db)
        ___init_with_dbi(cfg, db.get(ENV['PROJ'] ||= @cfg[:args].shift))
        ___init_dev_list(cfg)
      end

      def ___init_with_dbi(cfg, dbi)
        # pick already includes :command, :version
        cfg.update(dbi.pick([:sites, :id]))
        cfg[:host] = host || dbi[:host]
        cfg[:port] = dbi[:port] || 55_555
        cfg[:jlist] = Hashx.new(
          port: dbi[:port], commands: dbi.list, label: dbi.label
        )
      end

      # site_cfg is branch from cfg
      # site_cfg is handover to App,Frm
      # atrb is Wat only
      def ___init_dev_list(cfg)
        # handover to Wat only
        id = cfg[:id]
        # handover to Wat, App
        site_cfg = cfg.gen(self)
        site_cfg.update(db: Ins::Db.new(id), proj: id, opt: sub_opt)
        dev_layer = self[:x] ? Hex : Wat
        cfg[:dev_list] = dev_layer::List.new(site_cfg, sites: cfg[:sites])
        cfg[:sv_stat] = Prompt.new(id, self)
        cfg[:rec_arc] = RecArc.new(id)
      end
    end

    # Prompt for Mcr
    class Prompt < Prompt
      def initialize(id, opt = {})
        super('mcr', id)
        # list: running macros
        init_array(:list)
        # run: sites in motion
        init_array(:run)
        # sid: serial ID
        init_str(:sid)
        init_flg(nonstop: '(nonstop)')
        up(:nonstop) if opt[:n]
      end
    end

    ConfOpts.new { |cfg| puts cfg.list } if __FILE__ == $PROGRAM_NAME
  end
end
