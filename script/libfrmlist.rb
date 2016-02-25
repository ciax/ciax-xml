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
      opt = GetOpts.new
      begin
        cfg = Config.new(option: opt.parse('ceh:lts') , site: ARGV.shift)
        List.new(cfg).ext_shell.shell
      rescue InvalidARGS
        opt.usage('(opt) [id]')
      end
    end
  end
end
