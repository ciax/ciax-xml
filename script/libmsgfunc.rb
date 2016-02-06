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
      fname = vardir('log') + 'error_' + tag + today + '.out'
      $stderr = Tee.new(fname)
    end

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
