#!/usr/bin/ruby
require 'libgetopts'
module CIAX
  ### Daemon Methods ###
  module Daemon
    include Msg

    module_function

    # Switch error output to file
    def err2file(tag)
      return if $stderr.is_a? Tee || !OPT[:b]
      outfile = Msg.vardir('log') + 'error_' + tag + Msg.today + '.out'
      $stderr = Tee.new(outfile)
    end

    def new_pid(base)
      Process.daemon(true, true)
      IO.write(base + '.pid', $PROCESS_ID)
    end

    def kill_pid(base)
      return unless test('r', base + '.pid')
      IO.foreach(base + '.pid') do |line|
        pid = line.to_i
        next unless pid > 0
        begin
          Process.kill(:TERM, pid)
        rescue
          nil
        end
      end
    end

    # Reloadable by HUP signal
    def daemon(tag)
      # Set ARGS in opt file
      base = Msg.vardir('run') + tag
      kill_pid(base)
      begin
        optfile = base + '.opt'
        load optfile if test('r', optfile)
        exe = yield
        err2file(tag) && new_pid(base)
        exe.server
        sleep
      rescue SignalException
        retry if $ERROR_INFO.message == 'SIGHUP'
      rescue InvalidID
        OPT.usage('(opt) [id] ....')
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
