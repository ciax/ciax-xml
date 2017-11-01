#!/usr/bin/ruby
require 'libprompt'
require 'libreclist'
require 'libmcrdb'
require 'libwatlist'

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
        check_keys([:opt])
        @opt = self[:opt]
        db = Db.new
        update(layer_type: 'mcr', db: db)
        _init_with_dbi_(db.get(ENV['PROJ'] || self[:args].shift))
        _init_dev_list_(root_cfg.gen(self))
      end

      private

      def _init_with_dbi_(dbi)
        # pick already includes :command, :version
        update(dbi.pick([:sites, :id]))
        self[:host] = @opt.host || dbi[:host]
        self[:port] = dbi[:port] || 55_555
        self[:jlist] = Hashx.new(
          port: dbi[:port], commands: dbi.list, label: dbi.label
        )
      end

      # self is branch from root_cfg
      # site_cfg is handover to App,Frm
      # atrb is Wat only
      def _init_dev_list_(site_cfg)
        # handover to Wat only
        id = self[:id]
        # handover to Wat, App
        site_cfg.update(db: Ins::Db.new(id), proj: id, opt: @opt.sub_opt)
        self[:dev_list] = Wat::List.new(site_cfg, sites: self[:sites])
        self[:sv_stat] = Prompt.new(id, @opt)
        self[:rec_list] = RecList.new
      end
    end

    # Prompt for Mcr
    class Prompt < Prompt
      def initialize(id, opt = {})
        super('mcr', id)
        init_array(:list)
        init_array(:run)
        init_str(:sid)
        init_flg(nonstop: '(nonstop)')
        up(:nonstop) if opt[:n]
      end
    end

    ConfOpts.new { |cfg| puts Conf.new(cfg).list } if __FILE__ == $PROGRAM_NAME
  end
end
