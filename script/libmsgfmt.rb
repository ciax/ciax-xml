#!/usr/bin/ruby
# Common Module
module CIAX
  ### Formatting methods ###
  module Msg
    INDENT = ' '
    CTLCODE = %i(NUL SOH STX ETX EOT ENQ ACK BEL BS HT LF VT FF CR SO SI
                 DLE DC1 DC2 DC3 DC4 NAK SYN ETB CAN EM SUB ESC FS GS RS US)

    module_function

    def indent(ind = 0)
      INDENT * (ind > 0 ? ind : 0)
    end

    # Colored format
    # specify color with :n (n =0..f) located between '%' and flag
    # (ex. '%:1s')
    def cformat(fmt, *ary)
      fmt.gsub!(/%.*?[a-zA-Z]/) do |m|
        m.sub!(/:(.)/, '')
        $+ ? colorize(m, $+.hex) : m
      end
      format(fmt, *ary)
    end

    # Color 1=red,2=green,4=blue,8=bright
    def colorize(text, c = nil)
      return '' if text == ''
      return text unless !NOCOLOR && STDERR.tty? && c
      (c ||= 7).to_i
      "\033[#{c >> 3};3#{c & 7}m#{text}\33[0m"
    end

    # Show Control Charactor with Color
    def visible(text)
      str = ''
      text.each_byte do |c|
        n = c.ord
        if n > 126
          str << colorize(format('(%x)', c), 4)
        elsif n < 32
          str << colorize(format('(%s)', CTLCODE[n]), 4)
        else
          str << c
        end
      end
      str
    end

    # Display DB item in one line fromat.
    #    title : description
    def item(key, val, kmax = nil)
      indent(1) + colorize(key, 3).ljust((kmax || 3) + 11) + ": #{val}"
    end

    # Query options
    def optlist(list)
      return '' if !list || list.empty?
      colorize("[#{list.join('/')}]?", 5)
    end

    # Display methods
    #   colm can be Array [[kn,vn], [kn,vn],...] or number
    def columns(h, colm = nil, ind = nil, cap = nil)
      return '' unless h
      cary = colm.is_a?(Array) ? colm : Array.new(colm || 2) { [0, 0] }
      lary = upd_column_ary(h, cary).map! { |a| __mk_line(h, a, cary, ind) }
      (cap ? lary.unshift(cap) : lary).join("\n")
    end

    # max string length of value and key in hash at each column
    def upd_column_ary(h, cary)
      h.keys.each_slice(cary.size).map do |al|
        al.each_with_index do |k, i|
          pair = cary[i]
          pair[0] = [k.size, pair[0]].max
          pair[1] = [h[k].size, pair[1]].max
        end
        al
      end
    end

    def __mk_line(h, a, cary, ind)
      a.map.with_index do|k, i|
        kx, vx = cary[i]
        indent(ind.to_i) + item(k, h[k], kx).ljust(kx + vx + 15)
      end.join('').rstrip
    end
  end
end
