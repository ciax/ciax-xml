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
      _chk_args(_kill_pids(tag))
      @layer = tag
      ConfOpts.new('[id] ...', options: ops + 'b', default: 's') do |cfg, args|
        @obj = yield(cfg, sites: args)
        _init_server(tag, cfg[:opt])
        _main_loop { yield(cfg, sites: args) }
      end
    end

    private

    def _main_loop
      @obj.run
      sleep
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
      _watch_threads
      _redirect(tag) if opt[:b]
      verbose { "Initiate Daemon Start [#{tag}] " + git_ver }
      tag_set(@obj.id)
    end

    def _detach
      # Child process (Stream/Pipe) will be closed by at_exit()
      #  as the main process exit in Process.daemon
      Process.daemon(true, true)
      _write_pid($PROCESS_ID)
      verbose { "Initiate Daemon Detached (#{$PROCESS_ID})" }
    end

    def _watch_threads
      Threadx::UdpLoop.new('Thread', 'daemon', @layer, 54_321) do |_line, _rhost|
        Threadx.list.to_s
      end
    end

    def _kill_pids(tag)
      @pidfile = vardir('run') + tag + '.pid'
      pids = _read_pids
      _write_pid('')
      'Nothing to do' unless pids.any? { |pid| _kill_pid(pid) }
    end

    def _chk_args(str)
      return unless ARGV.empty?
      msg(indent(1) + str, 3) if str
      exit(2)
    end

    def _kill_pid(pid)
      Process.kill(:TERM, pid.to_i)
      show cformat('%:1s Process Killed (%s)', 'Daemon', pid)
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
