#!/usr/bin/ruby
require 'libappexe'
# CIAX-XML
module CIAX
  # Application Layer
  module App
    # Application List
    class List < Site::List
      # cfg must have [:db]
      def initialize(cfg, atrb = {})
        super
        init_sub(Frm::List)
        store_db(@cfg[:db] ||= Ins::Db.new)
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
