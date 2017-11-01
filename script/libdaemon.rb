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
        _chk_args_(_kill_pids_(tag), args + opt.values)
        opt[:s] = true
        @obj = yield(cfg, sites: args)
        _init_server_(tag, opt)
        _main_loop_ { yield(cfg, sites: args) }
      end
    end

    private

    def _main_loop_
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
    def _init_server_(tag, opt)
      _detach_
      _redirect_(tag) if opt[:b]
      verbose { "Initiate Daemon Start [#{tag}] " + git_ver }
      tag_set(@obj.id)
    end

    def _detach_
      # Child process (Stream/Pipe) will be closed by at_exit()
      #  as the main process exit in Process.daemon
      Process.daemon(true, true)
      _write_pid($PROCESS_ID)
      verbose { "Initiate Daemon Detached (#{$PROCESS_ID})" }
    end

    def _kill_pids_(tag)
      @pidfile = vardir('run') + tag + '.pid'
      pids = _read_pids_
      _write_pid('')
      'Nothing to do' unless pids.any? { |pid| _kill_pid(pid) }
    end

    def _chk_args_(str, args)
      return if args.any?
      msg(indent(1) + str, 3) if str
      exit(2)
    end

    def _kill_pid(pid)
      Process.kill(:TERM, pid.to_i)
      show cformat('%:1s Process Killed (%s)', 'Daemon', pid)
    rescue
      nil
    end

    def _read_pids_
      return [] unless test('r', @pidfile)
      IO.readlines(@pidfile).keep_if { |l| l.to_i > 0 }
    end

    def _write_pid(pid)
      IO.write(@pidfile, pid)
    end

    def _redirect_(tag)
      verbose { 'Initiate STDERR redirect' }
      fname = _mk_name(tag, today)
      $stderr = File.new(fname, 'a')
      _mk_link_(fname, tag)
    end

    def _mk_link_(fname, tag)
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
