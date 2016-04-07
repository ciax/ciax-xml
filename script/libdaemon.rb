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
      ConfOpts.new('[id] ....', optstr) do |cfg, args, opt|
        opt[:s] = true
        kill_pid
        new_pid
        main_loop(opt, tag) { yield(cfg, args) }
      end
    end

    private

    def main_loop(opt, tag, &init_proc)
      init_server(&init_proc)
      err_redirect(opt, tag)
      sleep
    rescue SignalException
      Threadx.killall
      retry if $ERROR_INFO.message == 'SIGHUP'
    end

    def err_redirect(opt, tag)
      return if $stderr.is_a?(Tee) || !opt[:b]
      errout = vardir('log') + 'error_' + tag + today + '.out'
      $stderr = Tee.new(errout)
    end

    def init_server(&init_proc)
      optfile = @base + '.opt'
      load optfile if test('r', optfile)
      init_proc.call
    end

    # Background (Switch error output to file)
    def new_pid
      Process.daemon(true, true)
      IO.write(@base + '.pid', $PROCESS_ID)
    end

    def kill_pid
      pidfile = @base + '.pid'
      return unless test('r', pidfile)
      pids = IO.readlines(pidfile).keep_if { |l| l.to_i > 0 }
      IO.write(pidfile, '')
      pids.each do |pid|
        begin
          Process.kill(:TERM, pid.to_i)
          verbose { "Initialize Process Killed (#{pid})" }
        rescue
          nil
        end
      end
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
