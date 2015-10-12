#!/usr/bin/ruby
# Common Module
require 'libmsgfunc'
require 'libmsgmod'
require 'libmsgtime'

module CIAX
  ######################### Message Module #############################
  # Should be extended in module/class
  module Msg
    attr_accessor :cls_color
    START_TIME = Time.now
    @indent_base = 1
    # block takes array (shown by each line) or string
    # Description of values
    #   [val] -> taken from  xml (criteria)
    #   <val> -> taken from status (incoming)
    #   (val) -> calcurated from status
    def verbose(cond = true)
      return if !VERBOSE || !cond || @hide_inside
      data = yield
      (data.is_a?(Array) ? data : [data]).map do|line|
        msg = make_msg(line)
        next unless condition(msg)
        prt_lines(msg)
      end.compact.empty?
    end

    def warning(title)
      Kernel.warn make_msg(Msg.color(title.to_s, 3))
      self
    end

    def alert(title)
      Kernel.warn make_msg(Msg.color(title.to_s, 5))
      self
    end

    def errmsg
      Kernel.warn make_msg(Msg.color("#{$ERROR_INFO} at #{$ERROR_POSITION}", 1))
    end

    # @hide_inside is flag for hiding inside of enclose
    def enclose(title1, title2)
      @hide_inside = verbose { title1 }
      Msg.ver_indent(1)
      res = yield
    ensure
      Msg.ver_indent(-1)
      verbose { Kernel.format(title2, res) }
      @hide_inside = false
    end

    private

    def prt_lines(data)
      ind = 0
      base = Msg.ver_indent
      data.each_line do|line|
        Kernel.warn Msg.indent(base + ind) + line
        ind = 2
      end
      true
    end

    def make_msg(title)
      return unless title
      @head ||= make_head
      ts = "#{@head}:#{title}"
      return ts if STDERR.tty?
      pass = Kernel.format('%5.4f', Time.now - START_TIME)
      "[#{pass}]" + ts
    end

    def head_ary
      cary = []
      tc = Thread.current
      cpath = class_path
      ns = cpath.shift
      cary << [tc[:name] || 'Main', tc[:color] || 15]
      cary << [ns, ns_color(ns)]
      cary << [cpath.join('::'), @cls_color || 15]
    end

    def make_head
      Msg.indent(Msg.ver_indent) + head_ary.map do|str, color|
        Msg.color("#{str}", color)
      end.join(':')
    end

    def ns_color(ns)
      begin
        color = CIAX.const_get("#{ns}::NS_COLOR")
      rescue NameError
        Msg.msg("No color defined for #{ns}::NS_COLOR", 3)
        color = 7
      end
      color
    end

    # VER= makes setenv "" to VER otherwise nil
    def condition(msg)
      return if !VERBOSE || !msg
      return true if match_all
      title = msg.split("\n").first.upcase
      VERBOSE.split(',').any? do|s|
        s.split(':').all? do|e|
          title.include?(e.upcase)
        end
      end
    end

    def match_all
      Regexp.new('\*').match(VERBOSE)
    end

    def self.ver_indent(add = 0)
      @indent_base += add
    end
  end
end
