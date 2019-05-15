#!/usr/bin/env ruby
require 'libmsgtime'
# Array#to_s shows lines
class Array
  def to_s
    ary = compact
    return '' if ary.empty?
    ary.join("\n") + "\n"
  end
end

# Common Module
module CIAX
  ### Formatting methods ###
  module Msg
    INDENT = ' '.freeze
    CTLCODE = %i(NUL SOH STX ETX EOT ENQ ACK BEL BS HT
                 LF VT FF CR SO SI DLE DC1 DC2 DC3 DC4
                 NAK SYN ETB CAN EM SUB ESC FS GS RS US).freeze

    module_function

    def indent(ind = 0)
      INDENT * (ind > 0 ? ind : 0)
    end

    # Colored format
    # specify color with :n (n =0..f) located between '%' and flag
    # (ex. '%:1s')
    # Inspection format
    #  %p converts the object with inspect
    def cfmt(*ary)
      return '' unless (head = ary.shift)
      i = 0
      fmt = head.to_s.gsub(/%.*?[a-zA-Z]/) do |m|
        m = colorize(m, $+.hex) if m.sub!(/:(.)/, '')
        i += 1
        m
      end
      format(fmt, *ary)
    end

    # Color 1=red,2=green,4=blue,8=bright
    def colorize(text, c = nil)
      return '' if text == ''
      return text unless !ENV['NOCOLOR'] && $stderr.tty? && c
      (c ||= 7).to_i
      "\033[#{c >> 3};3#{c & 7}m#{text}\33[0m"
    end

    # Show Control Charactor with Color
    def visible(text)
      text.each_byte.map do |c|
        if c > 126
          colorize(format('(%x)', c), 4)
        elsif c < 32
          colorize(format('(%s)', CTLCODE[c]), 4)
        else
          c.chr
        end
      end.join
    end

    # Display DB item in one line fromat.
    #    title : description
    def itemize(key, val, kmax = nil)
      indent(1) + colorize(key, 3).ljust((kmax || 3) + 11) + ": #{val}"
    end

    # Query options
    def opt_listing(ary)
      return '' if !ary || ary.empty?
      colorize("[#{ary.join('/')}]?", 5)
    end

    # Display methods
    #   colm can be Array [[kn,vn], [kn,vn],...] or number
    def columns(h, colm = nil, ind = nil, cap = nil)
      return '' unless h
      cary = colm.is_a?(Array) ? colm : Array.new(colm || 2) { [0, 0] }
      lary = upd_column_ary(h, cary).map! { |a| ___mk_line(h, a, cary, ind) }
      (cap ? lary.unshift(cap) : lary).join("\n")
    end

    # Making ID string with Array
    def a2cid(ary)
      ary.to_a.flatten.compact.join(':')
    end

    def a2csv(ary, space = '')
      ary.to_a.flatten.compact.join(',' + space)
    end

    # max string length of value and key in hash at each column
    def upd_column_ary(h, cary)
      h.keys.each_slice(cary.size).map do |al|
        al.each_with_index do |k, i|
          r = [k.size, h[k].size]
          cary[i].map! { |p| [r.shift, p].max }
        end
        al
      end
    end

    def ___mk_line(h, a, cary, ind)
      a.map.with_index do |k, i|
        kx, vx = cary[i]
        indent(ind.to_i) + itemize(k, h[k], kx).ljust(kx + vx + 15)
      end.join('').rstrip
    end

    # Specific text for verbose
    #  verbose text for exec
    def _exe_text(*par)
      # Action, cmdstr, source, priority
      cfmt("Executing %s from '%s' with priority %s", *par)
    end

    def _conv_text(*par)
      cfmt('Conversion %s %p [%s]', *par)
    end
  end
end
