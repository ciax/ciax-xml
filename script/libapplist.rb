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
      opt = GetOpts.new
      begin
        opt.parse('ceh:lts')
        cfg = Config.new(option: opt, site: ARGV.shift)
        List.new(cfg).ext_shell.shell
      rescue InvalidARGS
        opt.usage('(opt) [id]')
      end
    end
  end
end
