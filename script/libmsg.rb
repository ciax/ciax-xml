#!/usr/bin/env ruby
# Common Module
require 'libmsgfile'
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

    # Returns T/F (Displayed or not)
    def verbose
      return unless ENV['VER'] && !@hide_inside
      return if (ver = ENV['VER'].tr('@', '')).empty?
      str = type?(yield, String)
      msg = __make_msg(str)
      return unless ___chk_ver(msg, ver) || (@enclosed ||= []).any?
      __prt_lines(msg)
      true
    end

    def info(*ary)
      show __make_msg(cfmt(*ary), 7)
      self
    end

    def warning(*ary)
      show __make_msg(cfmt(*ary), 3)
      self
    end

    def alert(*ary)
      show __make_msg(cfmt(*ary), 5)
      self
    end

    def watch(val)
      show __make_msg(cfmt('%p(%s) on %s', val, val.object_id, last_caller), 3)
      val
    end

    # For debugging
    def errmsg
      show __make_msg("ERROR:#{$ERROR_INFO} at\n", 1) +
           $ERROR_POSITION.join("\n")
      self
    end

    # @hide_inside is flag for hiding inside of enclose
    # returns enclosed contents to have no influence by this
    def enclose(title1, title2 = nil)
      (@enclosed ||= []) << verbose { title1 }
      Msg.ver_indent(1)
      res = yield
    ensure
      Msg.ver_indent(-1)
      __prt_lines(__make_msg(format(title2, res))) if @enclosed.pop && title2
    end

    private

    def __prt_lines(data)
      lines = data.split("\n")
      show Msg.indent(base = Msg.ver_indent) + lines.shift
      lines.each { |line| show Msg.indent(base + 2) + line }
    end

    def __make_msg(title, c = nil)
      return unless title
      __make_head(c ? Msg.colorize(title.to_s, c) : title.to_s)
    end

    def ___head_ary
      cary = []
      th = Thread.current[:name]
      cary << [th, Msg.th_color(th)] if th
      @layer ||= layer_name
      cary << [@layer, Msg.ns_color(@layer)] if @layer
      cls = class_path.pop
      cls << "(#{@id})" if @id
      cary << [cls, Msg.cls_color(cls)]
    end

    def __make_head(tail)
      Msg.indent(Msg.ver_indent) + (___head_ary.map do |str, color|
        Msg.colorize(str.to_s, color)
      end << tail).join(':')
    end

    # Override libmsgerr error output method
    # Adding header when error output is redirect to file
    def _err_text(ary)
      ary[0] = __make_head(ary[0]) unless $stderr.tty?
      ary.join("\n  ")
    end

    # VER= makes setenv "" to VER otherwise nil
    # VER example "str1:str2,str3!str4"
    def ___chk_ver(msg, ver)
      return unless ver && msg
      return true if /\*/ =~ ver
      title = msg.split("\n").first.upcase
      ver.upcase.split(',').any? do |s|
        ___chk_exp(title, *s.split('!'))
      end
    end

    def ___chk_exp(title, exp, *inv)
      return false if inv.any? { |x| title.include?(x) }
      /#{exp.gsub(/:/, '.*')}/ =~ title
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
