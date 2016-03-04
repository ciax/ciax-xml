#!/usr/bin/ruby
require 'libenumx'

module CIAX
  # Xml Module
  module Xml
    HEADER = '<?xml version="1.0" encoding="utf-8"?>'
    # XML Formatting Class
    class Format < Arrayx
      def initialize(ind = 0)
        @indent = ind
      end

      # single line element
      def element(tag, text, atrb = {})
        str = tag_begin(tag, atrb)
        if text
          str << format('>%s</%s>', text, tag)
        else
          str << '/>'
        end
        push(str)
      end

      def enclose(tag, atrb = {})
        sub = Format.new(@indent + 1)
        push(tag_begin(tag, atrb) + '>')
        push sub
        push(tag_end(tag))
        sub
      end

      def to_s
        flatten(@indent)
      end

      private

      def tag_begin(tag, atrb = {})
        str = format('  ' * @indent + '<%s', tag)
        atrb.each do|k, v|
          str << format(' %s="%s"', k, v)
        end
        str
      end

      def tag_end(tag)
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
