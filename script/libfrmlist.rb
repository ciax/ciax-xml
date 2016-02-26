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
      GetOpts.new('[id]', 'ceh:lts') do |opt|
        cfg = Config.new(option: opt, site: ARGV.shift)
        List.new(cfg).ext_shell.shell
      end
    end
  end
end
