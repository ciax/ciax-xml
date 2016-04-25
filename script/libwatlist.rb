#!/usr/bin/ruby
require 'libwatexe'

module CIAX
  # Watch Layer
  module Wat
    # Watch List
    class List < Site::List
      # cfg must have [:db]
      def initialize(cfg, atrb = Hashx.new)
        super
        @cfg[:option] = @cfg[:option].sub_opt
        @sub_list = App::List.new(@cfg)
        store_db(@cfg[:db] ||= Ins::Db.new)
      end

      def run(sites = [])
        super(sites.empty? ? @db.run_list : sites)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', 'ceh:l') do |cfg, args|
        List.new(cfg, site: args.shift).ext_shell.shell
      end
    end
  end
end
