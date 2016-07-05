#!/usr/bin/ruby
require 'libappexe'
# CIAX-XML
module CIAX
  # Application Layer
  module App
    # Application List
    class List < Site::List
      # cfg must have [:db]
      def initialize(cfg, atrb = Hashx.new)
        super
        store_db(@cfg[:db] ||= Ins::Db.new(@id))
        @sub_list = Frm::List.new(@cfg)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', 'ceh:ls') do |cfg, args|
        List.new(cfg, sites: args).run.ext_shell.shell
      end
    end
  end
end
