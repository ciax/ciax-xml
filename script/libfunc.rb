#!/usr/bin/ruby
require 'libdefine'
# Common Module
module CIAX
  ### Module Functions ###
  module Msg
    module_function

    # Messaging methods
    def progress(f = true)
      p = color(f ? '.' : 'x', 1)
      $stderr.print p
    end

    def msg(str = 'message', color = 2, ind = 0) # Display only
      warn color(str, color) + indent(ind)
    end

    def _w(var, str = '') # watch var for debug
      clr = ':' + caller(1).first.split('/').last
      if var.is_a?(Enumerable)
        res = color(str, 5) + clr + _prt_enum(var)
      else
        res = color(var, 5) + clr
      end
      warn res
    end

    def _prt_enum(var)
      res = color("(#{var.object_id})", 3)
      res << var.dup.extend(Enumx).path
    end

    # Exception methods
    def id_err(*ary) # Raise User error (Invalid User input)
      ary[0] = color(ary[0], 1)
      fail InvalidID, ary.join("\n  "), caller(1)
    end

    def cmd_err(*ary) # Raise User error (Invalid User input)
      ary[0] = color(ary[0], 1)
      fail InvalidCMD, ary.join("\n  "), caller(1)
    end

    def par_err(*ary) # Raise User error (Invalid User input)
      ary[0] = color(ary[0], 1)
      fail InvalidPAR, ary.join("\n  "), caller(1)
    end

    def cfg_err(*ary) # Raise Device error (Bad Configulation)
      ary[0] = color(ary[0], 1)
      fail ConfigError, ary.join("\n  "), caller(1)
    end

    def cc_err(*ary) # Raise Device error (Verification Failed)
      ary[0] = color(ary[0], 1)
      fail VerifyError, ary.join("\n  "), caller(1)
    end

    def com_err(*ary) # Raise Device error (Communication Failed)
      ary[0] = color(ary[0], 1)
      fail CommError, ary.join("\n  "), caller(1)
    end

    def str_err(*ary) # Raise Device error (Stream open Failed)
      ary[0] = color(ary[0], 1)
      fail StreamError, ary.join("\n  "), caller(1)
    end

    def relay(str)
      str = str ? color(str, 3) + ':' + $ERROR_INFO.to_s : ''
      fail $ERROR_INFO.class, str, caller(1)
    end

    def sv_err(*ary) # Raise Server error (Parameter type)
      ary[0] = color(ary[0], 1)
      fail ServerError, ary.join("\n  "), caller(2)
    end

    def abort(str = 'abort')
      Kernel.abort([color(str, 1), $ERROR_INFO.to_s].join("\n"))
    end

    def usage(str, code = 1)
      warn("Usage: #{$PROGRAM_NAME.split('/').last} #{str}")
      exit code
    end

    def exit(code = 1)
      warn($ERROR_INFO.to_s) if $ERROR_INFO
      Kernel.exit(code)
    end

    # Assertion
    def type?(name, *modules)
      src = caller(1)
      modules.each do|mod|
        unless name.is_a?(mod)
          res = "Parameter type error <#{name.class}> for (#{mod})"
          fail(ServerError, res, src)
        end
      end
      name
    end

    def data_type?(data, type)
      return data if data['type'] == type
      fail "Data type error <#{name.class}> for (#{mod})"
    end

    # Thread is main
    def fg?
      Thread.current == Thread.main
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

    def item(key, val, kmax = 3)
      indent(1) + color(key, 3).ljust(kmax + 11) + ": #{val}"
    end

    def now_msec
      (Time.now.to_f * 1000).to_i
    end

    def elps_sec(msec, base = nil)
      return 0 unless msec
      base ||= now_msec
      format('%.3f', (base - msec).to_f / 1000)
    end

    def elps_date(msec, base = now_msec)
      return 0 unless msec
      sec = (base - msec).to_f / 1000
      interval(sec)
    end

    def interval(sec)
      return format('%.1f days', sec / 86_400) if sec > 86_400
      if sec > 3600
        fmt = '%H:%M'
      elsif sec > 60
        fmt = "%M'%S\""
      else
        fmt = "%S\"%L"
      end
      Time.at(sec).utc.strftime(fmt)
    end

    def date(msec)
      Time.at(msec.to_f / 1000).inspect
    end

    # Color 1=red,2=green,4=blue,8=bright
    def color(text, c = nil)
      return '' if text == ''
      return text unless STDERR.tty? && c
      (c ||= 7).to_i
      "\033[#{c >> 3};3#{c & 7}m#{text}\33[0m"
    end

    def indent(ind = 0)
      INDENT * ind
    end

    # Query options
    def optlist(list)
      list.empty? ? '' : color("[#{list.join('/')}]?", 5)
    end

    ## class name handling
    # Full path class name in same namespace
    def context_constant(name, mod = nil)
      type?(name, String)
      mod ||= self.class
      mary = mod.to_s.split('::')
      mary.size.times do
        cpath = (mary + [name]).join('::')
        return eval(cpath) if eval("defined? #{cpath}")
        mary.pop
      end
      abort("No such constant #{name}")
    end

    def layer_module
      eval self.class.name.split('::')[1]
    end

    def class_path
      self.class.to_s.split('::')[1..-1]
    end

    def m2id(mod, pos = -1)
      mod.name.split('::')[pos].downcase
    end

    # Make Var dir if not exist
    def vardir(subdir)
      dir = "#{ENV['HOME']}/.var/#{subdir}/"
      FileUtils.mkdir_p(dir)
      dir
    end
  end
end
