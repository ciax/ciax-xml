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
    Start_time = Time.now
    @indent_base = 1
    # block takes array (shown by each line)
    # Description of values
    #   [val] -> taken from  xml (criteria)
    #   <val> -> taken from status (incoming)
    #   (val) -> calcurated from status
    def verbose(cond = true)
      return if !ENV['VER'] || !cond
      msg, data = make_title(yield)
      return unless @show_inside || condition(msg)
      prt_lines(msg)
      true
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

    def enclose(title1, title2)
      @show_inside = verbose { title1 }
      Msg.ver_indent(1)
      res = yield
    ensure
      Msg.ver_indent(-1)
      verbose { Kernel.format(title2, res) }
      @show_inside = false
    end

    # Private Method

    private

    def make_title(title)
      if title.is_a? Array
        data = title
        title = data.shift
      else
        data = []
      end
      [make_msg(title), data]
    end

    def prt_lines(data)
      ind=0
      base=Msg.ver_indent
      data.each_line do|line|
        Kernel.warn Msg.indent(base+ind) + line
        ind=2
      end
    end

    def make_msg(title)
      return unless title
      @head ||= make_head
      ts = "#{@head}:#{title}"
      return ts if STDERR.tty?
      pass = Kernel.format('%5.4f', Time.now - Start_time)
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
      return if !ENV['VER'] || !msg
      return true if Regexp.new('\*').match(ENV['VER'])
      ENV['VER'].split(',').any? do|s|
        s.split(':').all? do|e|
          msg.upcase.include?(e.upcase)
        end
      end
    end

    def self.ver_indent(add = 0)
      @indent_base += add
    end
  end
end
