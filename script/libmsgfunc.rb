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
    rescue SyntaxError, NoMethodError
      cfg_err("#{str} is not number")
    end

    def esc_code(str)
      return unless str
      eval("\"#{str}\"")
    end

    # variable keys of db will be converted to String
    # other fixed keys are Symbol
    def key2str(hash)
      return hash unless hash.is_a? Hash
      hash.each_value.select { |h| h.is_a? Hash }.each do |subh|
        sv = {}
        subh.each { |k, v| sv[k.to_s] = v }
        subh.replace sv
      end
      hash
    end

    def j2h(jstr = nil)
      key2str(JSON.parse(jstr, symbolize_names: true))
    rescue JSON::ParserError
      data_err('NOT JSON')
    end

    # Thread is main
    def fg?
      Thread.current == Thread.main
    end

    def xmlfiles(type)
      Dir.glob("#{__dir__}/../#{type}-*.xml").map { |f| File.absolute_path(f) }
    end

    def v1cfgdir
      "#{__dir__}/../config-v1"
    end

    # For information (e.g. macro)
    def show_fg(str = "\n")
      print(str) if fg?
    end

    # Make Var dir if not exist
    def vardir(subdir)
      dir = "#{ENV['HOME']}/.var/#{subdir}/"
      FileUtils.mkdir_p(dir)
      dir
    end

    # Git administration
    # Commit ID
    def git_ver
      '(git commit:' + _git('reflog').split(' ').first + ')'
    end

    # Set Tag
    def tag_set
      br = _git("branch|grep '^\*'").split(' ')[1]
      tagary = [PROGRAM, HOST, today]
      tag = format('%s@%s%d', *tagary)
      msgary = [ENV['PROJ'], br, RUBY_VERSION]
      msg = format('PROJECT = %s, BRANCH = %s, RUBY Ver = %s', *msgary)
      _git("tag -afm '#{msg}' '#{tag}'")
      tag
    end

    def _git(str)
      `cd #{__dir__};git #{str}`
    end
  end
end
