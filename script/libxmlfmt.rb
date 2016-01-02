#!/usr/bin/ruby
require 'libenumx'

module CIAX
  module Xml
    class Format < Arrayx
      def initialize
        @indent = 0
        push '<?xml version="1.0" encoding="utf-8"?>'
      end

      def mktag(tag, atrb = {})
        str = format('  ' * @indent + '<%s', tag)
        atrb.each do|k, v|
          str << format(' %s="%s"', k, v)
        end
        str
      end

      # single line element
      def indent(tag, atrb = {}, text = nil)
        str = mktag(tag, atrb)
        if text
          str << format(">%s</%s>", text, tag)
        else
          str << '/>'
        end
        str
      end

      def enclose(tag, atrb = {}, enum = nil)
        @indent += 1
        if enum
          ary = enum.map{ |a| yield a}.compact
        else
          ary = [yield].compact
        end
        @indent -= 1
        return if ary.empty?
        ary.unshift(mktag(tag, atrb)+'>')
        ary << format('  ' * @indent + "</%s>", tag)
      end

      def a2h(vals, *tags)
        atrb = {}
        vals.each do|val|
          atrb[tags.shift] = val
        end
        atrb
      end

      def hpick(hash, *tags)
        res = {}
        tags.each { |k| res[k] = hash[k.to_s] }
        res
      end
    end

    if __FILE__ == $PROGRAM_NAME
      doc = Format.new
      puts doc.enclose('html'){
        doc.enclose('body'){
          doc.indent('a',{},'ok')
        }
      }
    end
  end
end
