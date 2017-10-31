#!/usr/bin/ruby
require 'libfrmexe'
require 'libsitelist'

module CIAX
  # Frame Layer
  module Frm
    Msg.deep_include(Frm, Site)
    # Frame List module
    class List
      def initialize(cfg, atrb = Hashx.new)
        super
        store_db(Dev::Db.new)
      end

      private

      def switch(site)
        get(site)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', options: 'cehls') do |cfg, args|
        List.new(cfg, sites: args).ext_shell.shell
      end
    end
  end
end
