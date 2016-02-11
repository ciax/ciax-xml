#!/usr/bin/ruby
require 'libgetopts'
module CIAX
  ### Daemon Methods ###
  class Daemon
    NS_COLOR = 1
    include Msg
    # Reloadable by HUP signal
    def initialize(tag, opt = '')
      ENV['VER'] ||= 'Initialize'
      # Set ARGS in opt file
      base = vardir('run') + tag
      kill_pid(base)
      begin
        OPT.parse(opt)
        optfile = base + '.opt'
        load optfile if test('r', optfile)
        exe = yield
        err2file(tag) && new_pid(base)
        exe.server
        sleep
      rescue SignalException
        retry if $ERROR_INFO.message == 'SIGHUP'
      rescue UserError
        OPT.usage('(opt) [id] ....')
      end
    end

    private

    # Switch error output to file
    def err2file(tag)
      return unless OPT[:b]
      return if $stderr.is_a? Tee
      outfile = vardir('log') + 'error_' + tag + today + '.out'
      $stderr = Tee.new(outfile)
    end

    def new_pid(base)
      Process.daemon(true, true)
      IO.write(base + '.pid', $PROCESS_ID)
    end

    def kill_pid(base)
      pidfile = base + '.pid'
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
