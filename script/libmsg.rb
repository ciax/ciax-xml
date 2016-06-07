#!/usr/bin/ruby
# Common Module
require 'libmsgfunc'
require 'libmsgmod'
# CIAX
module CIAX
  ######################### Message Module #############################
  # Should be extended in module/class
  TH_COLORS = {}
  NS_COLORS = {}
  CLS_COLORS = {}
  # Message module
  module Msg
    START_TIME = Time.now
    @indent_base = 1
    # block takes array (shown by each line) or string
    # Description of values
    #   [val] -> taken from  xml (criteria)
    #   <val> -> taken from status (incoming)
    #   (val) -> calcurated from status
    def verbose(cond = true)
      return self unless ENV['VER'] && cond && !@hide_inside
      str = type?(yield, String)
      msg = make_msg(str)
      prt_lines(msg) if condition(msg)
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
      data.each_line do|line|
        show Msg.indent(base + ind) + line
        ind = 2
      end
      @printed = true
    end

    def make_msg(title, c = nil)
      @printed = false
      return unless title
      @head ||= make_head
      ts = "#{@head}:"
      ts << (c ? Msg.colorize(title.to_s, c) : title.to_s)
    end

    def head_ary
      cary = []
      th = Thread.current[:name]
      ns = @layer
      cls = class_path.pop
      cls << "(#{@id})" if @id
      cary << [th, th_color(th)]
      cary << [ns, ns_color(ns)]
      cary << [cls, cls_color || 15]
    end

    def make_head
      Msg.indent(Msg.ver_indent) + head_ary.map do|str, color|
        Msg.colorize(str.to_s, color)
      end.join(':')
    end

    def th_color(ns)
      TH_COLORS[ns.to_s] ||= _gen_color(TH_COLORS)
    end

    def ns_color(ns)
      NS_COLORS[ns.to_s] ||= _gen_color(NS_COLORS, 1)
    end

    def cls_color
      cls = class_path.last
      CLS_COLORS[cls] ||= _gen_color(CLS_COLORS, 2)
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

    def _gen_color(table, ofs = 0)
      15 - (table.size + ofs) % 15
    end
  end
end
