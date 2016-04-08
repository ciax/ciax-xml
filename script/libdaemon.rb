#!/usr/bin/ruby
require 'libconf'
module CIAX
  ### Daemon Methods ###
  class Daemon
    include Msg
    # Previous process will be killed at the start up.
    # Reloadable by HUP signal
    def initialize(tag, optstr = '')
      ENV['VER'] ||= 'Initialize'
      # Set ARGS in opt file
      @base = vardir('run') + tag
      get_default
      ConfOpts.new('[id] ....', optstr) do |cfg, args, opt|
        opt[:s] = true
        kill_pids && args.empty? && exit
        new_pid
        main_loop(opt, tag) { yield(cfg, args) }
      end
    end

    private

    def main_loop(opt, tag, &init_proc)
      init_proc.call
      err_redirect(opt, tag)
      sleep
    rescue SignalException
      Threadx.killall
      retry if $ERROR_INFO.message == 'SIGHUP'
    end

    def err_redirect(_opt, tag)
      return if $stderr.is_a?(Tee)
      errout = vardir('log') + 'error_' + tag + today + '.out'
      $stderr = Tee.new(errout)
    end

    def get_default
      optfile = @base + '.opt'
      load optfile if test('r', optfile)
    end

    # Background (Switch error output to file)
    def new_pid
      Process.daemon(true, true)
      _write_pid($PROCESS_ID)
    end

    def kill_pids
      pids = _read_pids
      _write_pid('')
      pids.any? { |pid| _kill_pid(pid) }
    end

    def _read_pids
      pidfile = @base + '.pid'
      return [] unless test('r', pidfile)
      IO.readlines(pidfile).keep_if { |l| l.to_i > 0 }
    end

    def _write_pid(pid)
      IO.write(@base + '.pid', pid)
    end

    def _kill_pid(pid)
      Process.kill(:TERM, pid.to_i)
      verbose { "Initialize Process Killed (#{pid})" }
    rescue
      nil
    end

    # append str to stderr and file like tee
    class Tee < IO
      def initialize(fname)
        super(2)
        @io = File.open(fname, 'a')
      end

      def write(str)
        pass = format('%5.4f', Time.now - START_TIME)
        @io.write("[#{Time.now}/#{pass}]" + str)
        super
      end
    end
  end
end
