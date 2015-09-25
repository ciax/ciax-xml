#!/usr/bin/ruby
require "libmcrman"
require "libsitelayer"

module CIAX
  module Mcr
    # list object can be (Frm,App,Wat,Hex)
    # attr can have [:top_layer]
    class Layer < Site::Layer
      def initialize(attr={})
        super(:top_layer => Wat::List)
        put('mcr',Man::Exe.new(@cfg,{:dev_list => get('app')}))
        @current='mcr'
      end
    end

    if __FILE__ == $0
      require "libhexexe"
      ENV['VER']||='initialize'
      GetOpts.new("els")
      begin
        Layer.new.ext_shell.shell
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
