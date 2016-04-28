#!/usr/bin/ruby
require 'libconf'
require 'libprompt'

module CIAX
  # Macro Layer
  module Mcr
    # Mcr Common Parameters
    # Conf includes:
    # :layer_type, :db, :command, :version, :sites, :dev_list, :sv_stat
    # :host, :port
    class Conf < Config
      def initialize(cfg)
        super(cfg)
        db = Db.new
        dbi = db.get
        update(layer_type: 'mcr', db: db)
        # pick already includes :command, :version
        update(dbi.pick([:sites, :id]))
        _init_net(dbi)
        _init_dev_list(cfg)
      end

      private

      def _init_net(dbi)
        self[:host] = self[:option].host || dbi[:host]
        self[:port] = dbi[:port] || 55_555
      end

      # Take App List
      def _init_dev_list(cfg)
        atrb = { site: self[:sites].first, src: 'macro' }
        atrb[:option] = self[:option].sub_opt
        self[:dev_list] = Wat::List.new(cfg, atrb)
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
