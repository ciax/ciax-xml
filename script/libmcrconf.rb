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
    # :command, :version, :sites, :dev_list, :sv_stat :host, :port
    class ConfOpts < ConfOpts
      def initialize(ustr = '', optargs = {})
        super do |cfg, args|
          verbose { 'Initiate Mcr Conf (option:' + keys.join + ')' }
          proj = (ENV['PROJ'] ||= args.shift)
          cfg[:proj] = proj
          cfg[:sv_stat] = Prompt.new(proj, self)
          cfg[:dbi] = Db.new.get(proj)
          cfg[:rec_arc] = RecArc.new
          yield(cfg, args)
        end
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

    ConfOpts.new { |cfg| puts cfg.path } if __FILE__ == $PROGRAM_NAME
  end
end
