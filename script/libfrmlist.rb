#!/usr/bin/ruby
require 'libfrmexe'
require 'libsitelist'

module CIAX
  # Frame Layer
  module Frm
    LAYERS << 'frm'
    deep_include(Site)
    # Frame List module
    class List
      def initialize(super_cfg, atrb = Hashx.new)
        super
        ddb = Dev::Db.new
        ddb.put_idb(@cfg[:db]) if @cfg[:db].is_a?(Ins::Db)
        _store_db(ddb)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg, args|
        List.new(cfg, sites: args).ext_shell.shell
      end
    end
  end
end
