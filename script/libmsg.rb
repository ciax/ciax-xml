#!/usr/bin/ruby
# Common Module
require 'fileutils'
require 'libdefine'
require 'libfunc'
module CIAX
  ######################### Message Module #############################
  # Should be extended in module/class
  module Msg
    attr_accessor :cls_color
    Start_time = Time.now
    @@base = 1
    # Public Method
    def verbose(cond = true)
      # block takes array (shown by each line)
      # Description of values
      #   [val] -> taken from  xml (criteria)
      #   <val> -> taken from status (incoming)
      #   (val) -> calcurated from status
      if cond && ENV['VER']
        @ver_indent = @@base
        title = yield
        case title
        when Array
          data = title
          title = data.shift
        end
        msg = make_msg(title)
        if @show_inside || msg && condition(msg.to_s)
          Kernel.warn msg
          if data
            data.each{|str|
              str.to_s.split("\n").each{|line|
                Kernel.warn Msg.indent(@ver_indent + 1) + line
              }
            }
          end
          true
        end
      end
    end

    def ver?
      !ENV['VER'].to_s.empty?
    end

    def warning(title)
      @ver_indent = @@base
      Kernel.warn make_msg(Msg.color(title.to_s, 3))
      self
    end

    def alert(title)
      @ver_indent = @@base
      Kernel.warn make_msg(Msg.color(title.to_s, 5))
      self
    end

    def errmsg
      @ver_indent = @@base
      Kernel.warn make_msg(Msg.color("#{$!} at #{$@}", 1))
    end

    def enclose(title1, title2)
      @show_inside = verbose { title1 }
      @@base += 1
      res = yield
    ensure
      @@base -= 1
      verbose { sprintf(title2, res) }
      @show_inside = false
    end

    # Private Method
    private
    def make_msg(title)
      return unless title
      pass = sprintf('%5.4f', Time.now - Start_time)
      ts = STDERR.tty? ? '' : "[#{pass}]"
      tc = Thread.current
      ts << Msg.indent(@ver_indent)
      ts << Msg.color("#{tc[:name] || 'Main'}:", tc[:color] || 15)
      cpath = class_path
      ns = cpath.shift
      cls = cpath.join('::')
      begin
        ns_color = eval("#{ns}::NS_COLOR")
      rescue NameError
        Msg.color("No #{ns}::NS_COLOR", 1)
        ns_color = 7
      end
      ts << Msg.color("#{ns}", ns_color)
      ts << ':'
      ts << Msg.color("#{cls}", @cls_color || 15)
      ts << ':'
      ts << title.to_s
    end

    # VER= makes setenv "" to VER otherwise nil
    def condition(msg)
      return unless msg
      return unless ver?
      return true if /\*/ === ENV['VER']
      ENV['VER'].split(',').any?{|s|
        s.split(':').all?{|e|
          msg.upcase.include?(e.upcase)
        }
      }
    end
  end
end
