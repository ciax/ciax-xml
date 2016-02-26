#!/usr/bin/ruby
require 'liblayer'
require 'libhexlist'

module CIAX
  # list object can be (Frm,App,Wat,Hex)
  # atrb can have [:top_layer]
  module Site
    class Layer < CIAX::Layer
      def initialize(optstr)
        super('[id]', optstr) do |opt|
          @cfg[:site] = ARGV.shift
          opt[:x] ? Hex::List : Wat::List
        end
        @current = @cfg[:option].layer
      end
    end

    Layer.new('elsx').ext_shell.shell if __FILE__ == $PROGRAM_NAME
  end
end
