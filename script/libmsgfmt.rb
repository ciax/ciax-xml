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
          str << colorize('(%x)' % c, 4)
        elsif n < 32
          str << colorize('(%s)' % CTLCODE[n], 4)
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

    def caption(text, c = nil, sep = nil)
      sep ||= '~'
      [sep, colorize(text, c || 2), sep].join(' ')
    end

    # Query options
    def optlist(list)
      return '' if !list || list.empty?
      colorize("[#{list.join('/')}]?", 5)
    end

    # Display methods
    def columns(h, clm = nil, ind = nil, cap = nil)
      return '' unless h
      kary = h.keys
      clm ||= 2
      kx = __ary_max(kary, clm)
      vx = __ary_max(kary.map { |k| h[k] }, clm)
      lary = kary.each_slice(clm).map { |a| __mk_line(h, a, kx, vx, ind) }
      (cap ? lary.unshift(cap) : lary).join("\n")
    end

    def __mk_line(h, a, kx, vx, ind)
      a.map.with_index do|k, i|
        indent(ind.to_i) + item(k, h[k], kx[i]).ljust(vx[i] + kx[i] + 15)
      end.join('').rstrip
    end

    # max string length of value and key in hash at each column
    def __ary_max(ary, clm)
      cols = Array.new(clm).map { [] }
      ary.each_with_index { |s, i| cols[i % clm] << s.to_s.size }
      cols.map(&:max)
    end
  end
end
