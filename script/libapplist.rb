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
        opt = @cfg[:option].sub_opt
        @sub_list = Frm::List.new(@cfg, option: opt)
        store_db(@cfg[:db] ||= Ins::Db.new)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id]', 'ceh:ls') do |cfg, args|
        List.new(cfg, site: args.shift).ext_shell.shell
      end
    end
  end
end
