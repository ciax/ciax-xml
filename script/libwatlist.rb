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
      GetOpts.new('[id]','ceh:lt') do |opt|
        cfg = Config.new(option: opt)
        cfg[:site] = ARGV.shift
        List.new(cfg).ext_shell.shell
      end
    end
  end
end
