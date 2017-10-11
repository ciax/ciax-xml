#!/usr/bin/ruby
# Common Module
require 'libmsgfunc'
require 'libmsgmod'
# CIAX
module CIAX
  ######################### Message Module #############################
  # Should be extended in module/class
  # Message module
  module Msg
    START_TIME = Time.now
    @indent_base = 1
    @th_colors = {}
    @ns_colors = {}
    @cls_colors = {}
    # block takes array (shown by each line) or string
    # Description of values
    #   [val] -> taken from  xml (criteria)
    #   <val> -> taken from status (incoming)
    #   (val) -> calcurated from status
    def verbose(cond = true)
      return cond unless ENV['VER'] && cond && !@hide_inside
      str = type?(yield, String)
      msg = make_msg(str)
      prt_lines(msg) if condition(msg)
      cond
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
      verbose { title1 }
      @enclosed = @printed
      Msg.ver_indent(1)
      res = yield
    ensure
      Msg.ver_indent(-1)
      prt_lines(make_msg(format(title2, res))) if @enclosed
    end

    private

    def prt_lines(data)
      ind = 0
      base = Msg.ver_indent
      data.each_line do |line|
        show Msg.indent(base + ind) + line
        ind = 2
      end
      @printed = true
    end

    def make_msg(title, c = nil)
      @printed = false
      return unless title
      ts = make_head + ':'
      ts << (c ? Msg.colorize(title.to_s, c) : title.to_s)
    end

    def head_ary
      cary = []
      th = Thread.current[:name]
      @layer ||= layer_name
      cls = class_path.pop
      cls << "(#{@id})" if @id
      cary << [th, Msg.th_color(th)]
      cary << [@layer, Msg.ns_color(@layer)]
      cary << [cls, Msg.cls_color(cls)]
    end

    def make_head
      Msg.indent(Msg.ver_indent) + head_ary.map do |str, color|
        Msg.colorize(str.to_s, color)
      end.join(':')
    end

    # VER= makes setenv "" to VER otherwise nil
    def condition(msg)
      return if !ENV['VER'] || !msg
      return true if match_all
      title = msg.split("\n").first.upcase
      ENV['VER'].split(',').any? do |s|
        s.split(':').all? do |e|
          title.include?(e.upcase)
        end
      end
    end

    def match_all
      Regexp.new('\*').match(ENV['VER'])
    end

    module_function

    def ver_indent(add = 0)
      @indent_base += add
    end

    def th_color(ns)
      @th_colors[ns.to_s] ||= _gen_color(@th_colors)
    end

    def ns_color(ns)
      @ns_colors[ns.to_s] ||= _gen_color(@ns_colors, 1)
    end

    def cls_color(cls)
      @cls_colors[cls] ||= _gen_color(@cls_colors, 2)
    end

    def _gen_color(table, ofs = 0)
      15 - (table.size + ofs) % 15
    end
  end
end
