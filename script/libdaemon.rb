#!/usr/bin/ruby
require 'libconf'
module CIAX
  ### Daemon Methods ###
  class Daemon
    include Msg
    # Previous process will be killed at the start up.
    # Reloadable by HUP signal
    def initialize(tag, optstr = '')
      _chk_args(_kill_pids(tag))
      ConfOpts.new('[id] ....', optstr + 'sb') do |cfg, args, opt|
        atrb = { sites: args }
        @obj = yield(cfg, atrb)
        _init_server(tag, opt)
        _main_loop { yield(cfg, atrb) }
      end
    end

    private

    def _main_loop
      @obj.run
      Process.waitall
    rescue SignalException
      Threadx.killall
      if $ERROR_INFO.message == 'SIGHUP'
        @obj = yield
        retry
      end
    end

    # Background (Switch error output to file)
    def _init_server(tag, opt)
      _detach
      _redirect(tag) if opt[:b]
    end

    def _detach
      # Child process (Stream/Pipe) will be closed by at_exit()
      #  as the main process exit in Process.daemon
      Process.daemon(true, true)
      _write_pid($PROCESS_ID)
      verbose { "Initiate Daemon Detached (#{$PROCESS_ID})" }
    end

    def _kill_pids(tag)
      @pidfile = vardir('run') + tag + '.pid'
      pids = _read_pids
      _write_pid('')
      '   Nothing to do' unless pids.any? { |pid| _kill_pid(pid) }
    end

    def _chk_args(msg)
      ENV['VER'] ||= 'Initiate'
      msg ? give_up(indent(1) + msg) : exit(2) if ARGV.empty?
      ARGV.unshift '-s'
    end

    def _kill_pid(pid)
      Process.kill(:TERM, pid.to_i)
      verbose { "Initiate Process Killed (#{pid})" }
    rescue
      nil
    end

    def _read_pids
      return [] unless test('r', @pidfile)
      IO.readlines(@pidfile).keep_if { |l| l.to_i > 0 }
    end

    def _write_pid(pid)
      IO.write(@pidfile, pid)
    end

    def _redirect(tag)
      verbose { 'Initiate STDERR redirect' }
      fname = _mk_name(tag, today)
      $stderr = File.new(fname, 'a')
      _mk_link(fname, tag)
    end

    def _mk_link(fname, tag)
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
