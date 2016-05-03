#!/usr/bin/ruby
require 'libconf'
require 'libprompt'

module CIAX
  # Macro Layer
  module Mcr
    # Mcr Common Parameters
    # Upper Conf expected: :option
    # Conf includes:
    # :layer_type, :db, :command, :version, :sites, :dev_list, :sv_stat
    # :host, :port
    class Conf < Config
      def initialize(root_cfg)
        super(root_cfg)
        db = Db.new
        dbi = db.get
        update(layer_type: 'mcr', db: db)
        # pick already includes :command, :version
        update(dbi.pick([:sites, :id]))
        _init_net(dbi)
        _init_dev_list(root_cfg.gen(self))
      end

      private

      def _init_net(dbi)
        self[:host] = self[:option].host || dbi[:host]
        self[:port] = dbi[:port] || 55_555
      end

      # self is branch from root_cfg
      # site_cfg is handover to App,Frm
      # atrb is Wat only
      def _init_dev_list(site_cfg)
        # handover to Wat only
        atrb = { src: 'macro', sites: self[:sites] }
        # handover to App,Frm
        site_cfg[:option] = self[:option].sub_opt
        self[:dev_list] = Wat::List.new(site_cfg, atrb)
        self[:sv_stat] = Prompt.new(self[:id], self[:option])
      end
    end

    # Prompt for Mcr
    class Prompt < Prompt
      def initialize(id, opt = {})
        super('mcr', id)
        add_array(:list)
        add_array(:run)
        add_str(:sid)
        add_flg(nonstop: '(nonstop)')
        up(:nonstop) if opt[:n]
      end
    end
  end
end
