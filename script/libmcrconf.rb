#!/usr/bin/ruby
require 'libconf'
require 'libprompt'
require 'libreclist'
require 'libmcrdb'

module CIAX
  # Macro Layer
  module Mcr
    # Mcr Common Parameters
    # Upper Conf expected: :option, :jump_groups, :jump_layer
    # Conf includes:
    # :layer_type, :db, :command, :version, :sites, :dev_list, :sv_stat
    # :host, :port
    class Conf < Config
      def initialize(root_cfg)
        super(root_cfg)
        @opt = self[:option]
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
        self[:host] = @opt.host || dbi[:host]
        self[:port] = dbi[:port] || 55_555
      end

      # self is branch from root_cfg
      # site_cfg is handover to App,Frm
      # atrb is Wat only
      def _init_dev_list(site_cfg)
        # handover to Wat only
        id = self[:id]
        # handover to Wat, App
        site_cfg.update(db: Ins::Db.new(id), proj: id, option: @opt.sub_opt)
        self[:dev_list] = Wat::List.new(site_cfg, sites: self[:sites])
        self[:sv_stat] = Prompt.new(id, @opt)
        self[:rec_list] = RecList.new
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
