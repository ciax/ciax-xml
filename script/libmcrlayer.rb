#!/usr/bin/ruby
require 'libmcrman'
require 'libsitelayer'

module CIAX
  module Mcr
    # list object can be (Frm,App,Wat,Hex)
    # attr can have [:top_layer]
    class Layer < Site::Layer
      def initialize(attr = {})
        super
        put('mcr', Man::Exe.new(@cfg, { dev_list: get('app') }))
        @current = 'mcr'
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libhexexe'
      ENV['VER'] ||= 'initialize'
      OPT.parse('els')
      begin
        Layer.new.ext_shell.shell
      rescue InvalidID
        OPT.usage('(opt) [id]')
      end
    end
  end
end
