#!/usr/bin/env ruby
require 'libconf'
require 'libthreadx'
require 'libudp'
module CIAX
  ### Daemon Methods ###
  class Daemon
    include Msg
    # Previous process will be killed at the start up.
    # Reloadable by HUP signal
    # Get Thread status by UDP:54321 connection
    # Closure should return an object having ('run' and 'id')
    def initialize(cfg, port = 54_321)
      ___set_env
      tag = $PROGRAM_NAME.split('/').last
      ___chk_args(___kill_pids(tag), cfg.args + cfg.opt.values)
      ___init_server(tag, cfg.opt, port)
      ___server(port) { yield cfg.opt.init_layer_mod }
    end

    private

    def ___set_env
      ENV['VER'] ||= 'Initiate'
      ENV['NOCACHE'] ||= '1'
    end

    def ___server(port)
      info('Start Layer %s', yield.class)
      msg = 'for Thread status'
      Udp::Server.new('daemon', 'top', port, msg).listen do |reg, _host|
        ['===== Thread List =====',
         Threadx.list.view(reg.chomp!), '(reg)?>'].join("\n")
      end
    rescue SignalException
      Threadx.killall
      retry if $ERROR_INFO.message == 'SIGHUP'
    end

    # Background (Switch error output to file)
    def ___init_server(tag, opt, port)
      info('Git Tagged [%s], Status Port [%s]', tag_set, port) if opt.git_tag?
      ___detach
      ___redirect(tag) if opt.bg?
      verbose { "Initiate Daemon Start [#{tag}] " + git_ver }
    end

    def ___detach
      # Child process (Stream/Pipe) will be closed by at_exit()
      #  as the main process exit in Process.daemon
      Process.daemon(true, true)
      __write_pid($PROCESS_ID)
      verbose { "Initiate Daemon Detached (#{$PROCESS_ID})" }
    end

    def ___kill_pids(tag)
      @pidfile = vardir('run') + tag + '.pid'
      pids = ___read_pids
      __write_pid('')
      'Nothing to do' unless pids.any? { |pid| ___kill_pid(pid) }
    end

    def ___chk_args(str, args)
      return if args.any?
      msg(indent(1) + str, 3) if str
      exit(2)
    end

    def ___kill_pid(pid)
      Process.kill(:TERM, pid.to_i)
      show cfmt('%:1s Process Killed (%s)', 'Daemon', pid)
    rescue
      nil
    end

    def ___read_pids
      return [] unless test('r', @pidfile)
      IO.readlines(@pidfile).keep_if { |l| l.to_i > 0 }
    end

    def __write_pid(pid)
      IO.write(@pidfile, pid)
    end

    def ___redirect(tag)
      verbose { 'Initiate STDERR redirect' }
      fname = __mk_name(tag, today)
      $stderr = File.new(fname, 'a')
      ___mk_link(fname, tag)
    end

    def ___mk_link(fname, tag)
      sname = __mk_name(tag)
      File.unlink(sname) if File.exist?(sname)
      File.symlink(fname, sname)
    end

    def __mk_name(tag, name = nil)
      str = "error_#{tag}"
      str << "_#{name}" if name
      vardir('log') + str + '.out'
    end

    # Error output redirection to Log File
    class File < File
      include Msg
      def initialize(fname, rw)
        super
        @base_time = now_msec
        write("\n")
      end

      def puts(str)
        super(format("[#{Time.now}/%s]%s", elps_date(@base_time), str))
      end
    end
  end
end
