#!/usr/bin/ruby
require 'libconf'
module CIAX
  ### Daemon Methods ###
  class Daemon
    include Msg
    # Previous process will be killed at the start up.
    # Reloadable by HUP signal
    def initialize(tag, optstr = '')
      ENV['VER'] ||= 'Initiate'
      _kill_pids(tag)
      noarg = ARGV.empty?
      ConfOpts.new('[id] ....', optstr) do |cfg, args, opt|
        noarg && exit
        opt[:s] = true
        _init_server(tag)
        _main_loop { yield(cfg, args) }
      end
    end

    private

    def _main_loop
      yield
      sleep
    rescue SignalException
      Threadx.killall
      retry if $ERROR_INFO.message == 'SIGHUP'
    end

    # Background (Switch error output to file)
    def _init_server(tag)
      Process.daemon(true, true)
      _write_pid($PROCESS_ID)
      verbose { "Initiate Daemon (#{$PROCESS_ID})" }
      _redirect(tag)
    end

    def _kill_pids(tag)
      @base = vardir('run') + tag
      pids = _read_pids
      _write_pid('')
      pids.any? { |pid| _kill_pid(pid) }
    end

    def _kill_pid(pid)
      Process.kill(:TERM, pid.to_i)
      verbose { "Initiate Process Killed (#{pid})" }
    rescue
      nil
    end

    def _read_pids
      pidfile = @base + '.pid'
      return [] unless test('r', pidfile)
      IO.readlines(pidfile).keep_if { |l| l.to_i > 0 }
    end

    def _write_pid(pid)
      IO.write(@base + '.pid', pid)
    end

    def _redirect(tag)
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
  end
end
