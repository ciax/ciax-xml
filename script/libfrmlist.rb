#!/usr/bin/ruby
require 'libfrmexe'
require 'libsitelist'

module CIAX
  # Frame Layer
  module Frm
    # Frame List module
    class List < Site::List
      def initialize(cfg, atrb = {})
        super
        store_db(Dev::Db.new)
      end

      private

      def switch(site)
        get(site)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', 'ceh:ls') do |cfg, args|
        List.new(cfg, site: args.shift).ext_shell.shell
      end
    end
  end
end
