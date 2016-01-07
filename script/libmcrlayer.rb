#!/usr/bin/ruby
require 'libmcrsh'
require 'liblayer'
# CIAX-XML
module CIAX
  module Mcr
    # list object can be (Frm,App,Wat,Hex)
    # attr can have [:top_layer]
    class Layer < Site::Layer
      def ext_mcr
        @list.put('mcr', Mcr::Man.new(@cfg, db: Mcr::Db.new, dev_list: @list.get('wat')))
        @current = 'mcr'
        self
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('els')
      begin
        Layer.new.ext_mcr.ext_shell.shell
      rescue InvalidID
        OPT.usage('(opt) [id]')
      end
    end
  end
end
