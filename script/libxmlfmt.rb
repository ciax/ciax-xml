#!/usr/bin/env ruby
require 'libhashx'

module CIAX
  # Xml Module
  module Xml
    HEADER = '<?xml version="1.0" encoding="utf-8"?>'.freeze
    # XML Formatting Class, used for generating Html (i.e. Html::Table)
    class Format < Arrayx
      def initialize(ind = 0)
        @indent = ind
      end

      # single line element
      def element(tag, text, atrb = Hashx.new)
        str = __tag_begin(tag, atrb)
        str << if text
                 format('>%s</%s>', text, tag)
               else
                 '/>'
               end
        push(str)
      end

      def enclose(tag, atrb = Hashx.new)
        sub = Format.new(@indent + 1)
        push(__tag_begin(tag, atrb) + '>')
        push sub
        push(___tag_end(tag))
        sub
      end

      def to_s
        flatten(@indent)
      end

      private

      def __tag_begin(tag, atrb = Hashx.new)
        str = format('  ' * @indent + '<%s', tag)
        atrb.each do |k, v|
          str << format(' %s="%s"', k, v)
        end
        str
      end

      def ___tag_end(tag)
        format('  ' * @indent + '</%s>', tag)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      doc = Format.new
      doc << HEADER
      html = doc.enclose('html')
      body = html.enclose('body')
      body.element('a', 'ok')
      puts doc
    end
  end
end
