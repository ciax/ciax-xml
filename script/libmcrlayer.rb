#!/usr/bin/ruby
require 'libmcrsh'
require 'liblayer'

module CIAX
  # list object can be (Frm,App,Wat,Hex)
  # attr can have [:top_layer]
  class Layer
    def ext_mcr
      put('mcr', Mcr::Man.new(@cfg, dev_list: get('app')))
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
