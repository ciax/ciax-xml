#!/usr/bin/env ruby
require 'libxmlcore'
require 'ox'

module CIAX
  # Xml module
  module Xml
    # Using Ox
    # gem install ox
    class Elem < Core
      def initialize(f)
        super
        @ns = @e[:xmlns]
        @attr = @e.attributes
      end

      def [](key)
        @e[key.to_sym]
      end

      def name
        @e.value
      end

      def each
        @e.each do |e|
          yield Elem.new(e) if e.is_a?(_element)
        end
      end

      def find(xpath)
        super
        @e.locate(xpath).each do |e|
          yield Elem.new(e)
        end
      end

      alias each_value each

      private

      def _element
        Ox::Element
      end

      def _get_file(f)
        Ox.load_file(f).root
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libgetopts'
      GetOpts.new('[type]') do |_o, args|
        file = Msg.xmlfiles(args.shift).first.to_s
        Msg.args_err(%w(adb fdb idb ddb mdb cdb sdb hdb).inspect) if file.empty?
        ele = Elem.new(file)
        ele.each { |e| puts e.name }
      end
    end
  end
end
