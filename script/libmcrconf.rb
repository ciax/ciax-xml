#!/usr/bin/ruby
require 'libprompt'
require 'libreclist'
require 'libmcrdb'
require 'libhexlist' # deprecated

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
        verbose { 'Initiate Mcr Conf (option:' + @opt.keys.join + ')' }
        db = Db.new
        update(layer_type: 'mcr', db: db)
        ___init_with_dbi(db.get(ENV['PROJ'] ||= self[:args].shift))
        ___init_dev_list(root_cfg.gen(self))
      end

      private

      def ___init_with_dbi(dbi)
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
      def ___init_dev_list(site_cfg)
        # handover to Wat only
        id = self[:id]
        # handover to Wat, App
        site_cfg.update(db: Ins::Db.new(id), proj: id, opt: @opt.sub_opt)
        dev_layer = @opt[:x] ? Hex : Wat
        self[:dev_list] = dev_layer::List.new(site_cfg, sites: self[:sites])
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
