#!/usr/bin/ruby
require "libmcrsh"

module CIAX
  module Mcr
    class Layer < ShLayer
      def initialize
        super
        update_layers(List.new.layers)
      end
    end

    GetOpts.new('r')
    Layer.new.shell('0')
  end
end
