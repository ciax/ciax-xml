#!/usr/bin/ruby
require 'libfrmexe'
require 'libsitelist'
# CIAX-XML
module CIAX
  # Frame Layer
  module Frm
    deep_include(Site)
    # Frame List module
    class List
      def initialize(super_cfg, atrb = Hashx.new)
        super
        ddb = Dev::Db.new(@cfg[:db].is_a?(Ins::Db) ? @cfg[:db].valid_devs : {})
        _store_db(ddb)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg, args|
        List.new(cfg, sites: args).shell
      end
    end
  end
  @top_layer = Frm
end
