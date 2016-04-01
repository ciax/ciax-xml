#!/usr/bin/ruby
# Common Module
require 'libmsgfunc'
require 'libmsgmod'

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
      return self unless ENV['VER'] && cond && !@hide_inside
      data = yield
      (data.is_a?(Array) ? data : [data]).map do|line|
        msg = make_msg(line)
        next unless condition(msg)
        prt_lines(msg)
      end
      self
    end

    def info(title)
      show make_msg(title, 2) unless $stderr.tty?
      self
    end

    def warning(title)
      show make_msg(title, 3)
      self
    end

    def alert(title)
      show make_msg(title, 5)
      self
    end

    def errmsg
      show make_msg("#{$ERROR_INFO} at #{$ERROR_POSITION}", 1)
      self
    end

    # @hide_inside is flag for hiding inside of enclose
    # returns enclosed contents to have no influence by this
    def enclose(title1, title2)
      @hide_inside = verbose { title1 }
      Msg.ver_indent(1)
      res = yield
    ensure
      Msg.ver_indent(-1)
      verbose { format(title2, res) }
      @hide_inside = false
    end

    private

    def prt_lines(data)
      ind = 0
      base = Msg.ver_indent
      data.each_line do|line|
        show Msg.indent(base + ind) + line
        ind = 2
      end
    end

    def make_msg(title, c = nil)
      return unless title
      @head ||= make_head
      ts = "#{@head}:"
      ts << (c ? Msg.colorize(title.to_s, c) : title.to_s)
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
        Msg.colorize(str.to_s, color)
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
      return if !ENV['VER'] || !msg
      return true if match_all
      title = msg.split("\n").first.upcase
      ENV['VER'].split(',').any? do|s|
        s.split(':').all? do|e|
          title.include?(e.upcase)
        end
      end
    end

    def match_all
      Regexp.new('\*').match(ENV['VER'])
    end

    def self.ver_indent(add = 0)
      @indent_base += add
    end
  end
end
