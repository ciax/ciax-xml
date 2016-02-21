#!/usr/bin/ruby
require 'libgetopts'
module CIAX
  ### Daemon Methods ###
  class Daemon
    NS_COLOR = 1
    include Msg
    # Reloadable by HUP signal
    def initialize(tag, optstr = '')
      ENV['VER'] ||= 'Initialize'
      # Set ARGS in opt file
      @base = vardir('run') + tag
      opt = GetOpts.new(optstr)
      cfg = Config.new(option: opt)
      if opt[:d]
        kill_pid
      else
        init_daemon(opt)
        begin
          init_server { yield(cfg) }.server
          err_redirect(opt,tag)
          sleep
        rescue SignalException
          retry if $ERROR_INFO.message == 'SIGHUP'
        end
      end
    rescue UserError
      opt.usage('(opt) [id] ....')
    end

    private

    def init_daemon(opt)
      kill_pid
      return unless opt[:b]
      # Background (Switch error output to file)
      new_pid
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
