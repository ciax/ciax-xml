#!/usr/bin/ruby
require 'libwatexe'

module CIAX
  # Watch Layer
  module Wat
    # Watch List
    class List < Site::List
      # cfg must have [:db]
      def initialize(cfg, atrb = {})
        super
        init_sub(App::List)
        store_db(@cfg[:db] ||= Ins::Db.new)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      opt = GetOpts.new('ceh:lt')
      cfg = Config.new(option: opt)
      cfg[:site] = ARGV.shift
      begin
        List.new(cfg).ext_shell.shell
      rescue InvalidID
        Msg.usage('(opt) [id]')
      end
    end
  end
end
