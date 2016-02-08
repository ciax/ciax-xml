#!/usr/bin/ruby
# Common Module
require 'libmsgdbg'
require 'libmsgtime'
require 'fileutils'
require 'json'
module CIAX
  ### Checking Methods ###
  module Msg
    module_function

    def expr(str)
      return unless str
      eval(str) || 0
    end

    def esc_code(str)
      return unless str
      eval('"' + str + '"')
    end

    # variable keys of db is String
    # other fixed keys are Symbol
    def j2h(json_str = nil)
      res = JSON.parse(json_str, symbolize_names: true)
      res.values.each do |val|
        next unless val.is_a? Hash
        sv = {}
        val.each { |k, v| sv[k.to_s] = v }
        val.replace sv
      end if res.is_a? Hash
      res
    rescue JSON::ParserError
      usr_err('NOT JSON')
    end

    # Thread is main
    def fg?
      Thread.current == Thread.main
    end

    def xmlfiles(type)
      Dir.glob("#{__dir__}/../#{type}-*.xml")
    end

    def v1cfgdir
      "#{__dir__}/../config-v1"
    end

    # Make Var dir if not exist
    def vardir(subdir)
      dir = "#{ENV['HOME']}/.var/#{subdir}/"
      FileUtils.mkdir_p(dir)
      dir
    end

    # Switch error output to file
    def err2file(tag)
      return if $stderr.is_a? Tee
      outfile = vardir('log') + 'error_' + tag + today + '.out'
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
      base = vardir('run') + tag
      kill_pid(base)
      begin
        load optfile if test('r', base + '.opt')
        exe = yield
        err2file(tag) && new_pid(base)
        exe.server
        sleep
      rescue SignalException
        retry if $ERROR_INFO.message == 'SIGHUP'
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
