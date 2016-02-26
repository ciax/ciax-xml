#!/usr/bin/ruby
require 'liblayer'
require 'libmcrsh'

module CIAX
  module Mcr
    class Layer < CIAX::Layer
      def initialize(optstr)
        super('[proj] [cmd] (par)', optstr) do |_opt|
          Mcr::Man
        end
      end
    end

    Layer.new('elsx').ext_shell.shell if __FILE__ == $PROGRAM_NAME
  end
end
