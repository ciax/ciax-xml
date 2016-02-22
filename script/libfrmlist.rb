#!/usr/bin/ruby
require 'libfrmexe'
require 'libsitelist'

module CIAX
  # Frame Layer
  module Frm
    # Frame List module
    class List < Site::List
      def initialize(cfg)
        super(cfg)
        store_db(Dev::Db.new)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      opt = GetOpts.new('ceh:lts')
      cfg = Config.new(option: opt)
      cfg[:site] = ARGV.shift
      begin
        List.new(cfg).ext_shell.shell
      rescue InvalidID
        opt.usage('(opt) [id]')
      end
    end
  end
end
