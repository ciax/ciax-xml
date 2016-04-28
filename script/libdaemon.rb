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
      # Set ARGS in opt file
      @base = vardir('run') + tag
      noarg = ARGV.empty?
      _kill_pids
      ConfOpts.new('[id] ....', optstr) do |cfg, args, opt|
        noarg && exit
        _init_server(opt, tag)
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
    def _init_server(opt, tag)
      opt[:s] = true
      Process.daemon(true, true)
      _write_pid($PROCESS_ID)
      $stderr = Tee.new(tag, today)
    end

    def _kill_pids
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
      verbose { "Initiate Process Killed (#{pid})" }
    rescue
      nil
    end

    # append str to stderr and file like tee
    class Tee < IO
      include Msg
      def initialize(tag, date)
        super(2, 'w')
        fname = _mk_name(tag, date)
        @io = File.open(fname, 'a')
        @io.write("\n")
        write(make_msg("Initiate STDERR Redirection\n"))
        sname = _mk_name(tag)
        File.unlink(sname) if File.exist?(sname)
        File.symlink(fname, sname)
      end

      def write(str)
        pass = format('%5.4f', Time.now - START_TIME)
        @io.write("[#{Time.now}/#{pass}]" + str)
        reopen('/dev/null/') if closed?
        super
      rescue
        @io.puts($ERROR_INFO)
      end

      private

      def _mk_name(tag, name = nil)
        str = "error_#{tag}"
        str << "_#{name}" if name
        vardir('log') + str + '.out'
      end
    end
  end
end
