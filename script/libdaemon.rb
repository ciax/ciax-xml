#!/usr/bin/ruby
require 'libconf'
require 'libthreadx'
module CIAX
  ### Daemon Methods ###
  class Daemon
    include Msg
    # Previous process will be killed at the start up.
    # Reloadable by HUP signal
    # Get Thread status by UDP:54321 connection
    def initialize(tag, ops = '')
      ENV['VER'] ||= 'Initiate'
      @layer = tag
      ConfOpts.new('[id] ...', options: ops + 'b') do |cfg, args|
        opt = cfg[:opt]
        ___chk_args(___kill_pids(tag), args + opt.values)
        opt[:s] = true
        @obj = yield(cfg, sites: args)
        ___init_server(tag, opt)
        ___main_loop { yield(cfg, sites: args) }
      end
    end

    private

    def ___main_loop
      @obj.run
      Udp::Server.new('sv', 'top', 54_321).listen { Threadx.list.to_s }
    rescue SignalException
      Threadx.killall
      if $ERROR_INFO.message == 'SIGHUP'
        @obj = yield
        retry
      end
    end

    # Background (Switch error output to file)
    def ___init_server(tag, opt)
      ___detach
      ___redirect(tag) if opt[:b]
      verbose { "Initiate Daemon Start [#{tag}] " + git_ver }
      tag_set(@obj.id)
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
      show cformat('%:1s Process Killed (%s)', 'Daemon', pid)
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
      fname = _mk_name(tag, today)
      $stderr = File.new(fname, 'a')
      ___mk_link(fname, tag)
    end

    def ___mk_link(fname, tag)
      sname = _mk_name(tag)
      File.unlink(sname) if File.exist?(sname)
      File.symlink(fname, sname)
    end

    def _mk_name(tag, name = nil)
      str = "error_#{tag}"
      str << "_#{name}" if name
      vardir('log') + str + '.out'
    end

    # Error output redirection to Log File
    class File < File
      include Msg
      def initialize(fname, rw)
        super
        @base = now_msec
        write("\n")
      end

      def puts(str)
        super(format("[#{Time.now}/%s]%s", elps_date(@base), str))
      end
    end
  end
end
