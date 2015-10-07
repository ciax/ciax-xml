#!/usr/bin/ruby
# Common Module
module CIAX
  ### Formatting methods ###
  module Msg
    INDENT = '  '

    module_function

    def indent(ind = 0)
      INDENT * ind
    end

    # Colored format
    # specify color with :n (n =0..f) located between '%' and flag
    # (ex. '%:1s')
    def cformat(fmt, *ary)
      fmt.gsub!(/%.*?[a-zA-Z]/) do |m|
        m.sub!(/:(.)/, '')
        $+ ? color(m, $+.hex) : m
      end
      format(fmt, *ary)
    end

    # Color 1=red,2=green,4=blue,8=bright
    def color(text, c = nil)
      return '' if text == ''
      return text unless STDERR.tty? && c
      (c ||= 7).to_i
      "\033[#{c >> 3};3#{c & 7}m#{text}\33[0m"
    end

    # Display DB item in one line fromat.
    #    title : description
    def item(key, val, kmax = 3)
      indent(1) + color(key, 3).ljust(kmax + 11) + ": #{val}"
    end

    # Query options
    def optlist(list)
      list.empty? ? '' : color("[#{list.join('/')}]?", 5)
    end

    # Display methods
    def columns(h, c = 2, vx = nil, kx = nil)
      vx, kx = _max_size(h, vx, kx)
      h.keys.each_slice(c).map do|a|
        a.map do|k|
          item(k, h[k], kx).ljust(vx + kx + 15)
        end.join('').rstrip
      end.join("\n")
    end

    # max string length of value and key in hash
    def _max_size(hash, vx = nil, kx = nil)
      vx ||= hash.values.map(&:size).max
      kx ||= hash.keys.map(&:size).max
      [vx, kx]
    end
  end
end
