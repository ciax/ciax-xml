#!/usr/bin/ruby
# Common Module
module CIAX
  module Msg
    ########################## Module Functions ###########################
    module_function
    # Messaging methods
    def progress(f = true)
      p = color(f ? '.' : 'x', 1)
      $stderr.print p
    end

    def msg(msg = 'message', color = 2, ind = 0) # Display only
      Kernel.warn color(msg, color) + indent(ind)
    end

    def _w(var, msg = '') # watch var for debug
      if var.kind_of?(Enumerable)
        Kernel.warn color(msg, 5) + color("(#{var.object_id})", 3) + ':' + caller(1).first.split('/').last
        Kernel.warn var.dup.extend(Enumx).path
      else
        Kernel.warn color(var, 5) + ':' + caller(1).first.split('/').last
      end
    end

    # Exception methods
    def id_err(*msg) # Raise User error (Invalid User input)
      msg[0] = color(msg[0], 1)
      raise InvalidID, msg.join("\n  "), caller(1)
    end

    def cmd_err(*msg) # Raise User error (Invalid User input)
      msg[0] = color(msg[0], 1)
      raise InvalidCMD, msg.join("\n  "), caller(1)
    end

    def par_err(*msg) # Raise User error (Invalid User input)
      msg[0] = color(msg[0], 1)
      raise InvalidPAR, msg.join("\n  "), caller(1)
    end

    def cfg_err(*msg) # Raise Device error (Bad Configulation)
      msg[0] = color(msg[0], 1)
      raise ConfigError, msg.join("\n  "), caller(1)
    end

    def vfy_err(*msg) # Raise Device error (Verification Failed)
      msg[0] = color(msg[0], 1)
      raise VerifyError, msg.join("\n  "), caller(1)
    end

    def com_err(*msg) # Raise Device error (Communication Failed)
      msg[0] = color(msg[0], 1)
      raise CommError, msg.join("\n  "), caller(1)
    end

    def str_err(*msg) # Raise Device error (Stream open Failed)
      msg[0] = color(msg[0], 1)
      raise StreamError, msg.join("\n  "), caller(1)
    end

    def relay(msg)
      msg = msg ? color(msg, 3) + ':' + $!.to_s : ''
      raise $!.class, msg, caller(1)
    end

    def sv_err(*msg) # Raise Server error (Parameter type)
      msg[0] = color(msg[0], 1)
      raise ServerError, msg.join("\n  "), caller(2)
    end

    def abort(msg = 'abort')
      Kernel.abort([color(msg, 1), $!.to_s].join("\n"))
    end

    def usage(str, code = 1)
      Kernel.warn("Usage: #{$0.split('/').last} #{str}")
      exit code
    end

    def exit(code = 1)
      Kernel.warn($!.to_s) if $!
      Kernel.exit(code)
    end

    # Assertion
    def type?(name, *modules)
      src = caller(1)
      modules.each{|mod|
        unless name.is_a?(mod)
          raise(ServerError, "Parameter type error <#{name.class}> for (#{mod})", src)
        end
      }
      name
    end

    def data_type?(data, type)
      return data if data['type'] == type
      raise "Data type error <#{name.class}> for (#{mod})"
    end

    # Thread is main
    def fg?
      Thread.current == Thread.main
    end

    # Display methods
    def columns(hash, column = 2, vmax = nil, kmax = nil)
      page = []
      vmax ||= hash.values.map { |v| v.size }.max
      kmax ||= hash.keys.map { |k| k.size }.max
      hash.keys.each_slice(column){|a|
        line = ''
        a.each_with_index{|key, i|
          val = hash[key]
          line << item(key, val, kmax)
          line << ' ' * [vmax - val.size, 0].max if a.size - 1 > i
        }
        page << line
      }
      page.compact.join("\n")
    end

    def item(key, val, kmax = 3)
      indent(1) + color("%-#{kmax + 1}s" % key, 3) + ": #{val}"
    end

    def now_msec
      (Time.now.to_f * 1000).to_i
    end

    def elps_sec(msec, base = nil)
      return 0 unless msec
      base ||= now_msec
      '%.3f' % ((base - msec).to_f / 1000)
    end

    def elps_date(msec, base = now_msec)
      return 0 unless msec
      sec = (base - msec).to_f / 1000
      if sec > 86400
        '%.1f days' % (sec / 86400)
      elsif sec > 3600
        Time.at(sec).utc.strftime('%H:%M')
      elsif sec > 60
        Time.at(sec).utc.strftime("%M'%S\"")
      else
        Time.at(sec).utc.strftime("%S\"%L")
      end
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
      mary.size.times{
        cpath = (mary + [name]).join('::')
        if eval("defined? #{cpath}")
          return eval(cpath)
        end
        mary.pop
      }
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
