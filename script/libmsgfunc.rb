#!/usr/bin/env ruby
# Common Module
require 'libmsgdbg'
require 'json'
module CIAX
  ### Checking Methods ###
  module Msg
    def Math.bind
      binding
    end

    module_function

    # You can use Math functions in str
    def expr(str)
      return unless str
      eval(str, Math.bind) || 0
    rescue SyntaxError, NameError
      cfg_err("#{str} is not number")
    end

    def esc_code(str)
      return unless str
      eval("\"#{str}\"")
    end

    # Use num.clamp() on ruby 2.4 or later
    # the order of range parameters is not concerned
    def limit(num, *rg)
      [[rg.min, num].max, rg.max].min
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

    # Json feature
    def j2h(jstr = nil)
      key2str(JSON.parse(jstr || '', symbolize_names: true))
    rescue JSON::ParserError
      data_err('NOT JSON [%p]', jstr)
    end

    # Thread is main
    def fg?
      Thread.current == Thread.main
    end

    # For information (e.g. macro)
    def show_fg(str = "\n")
      print(str) if fg?
      self
    end

    # Encode/Decode base64
    def enc64(binstr)
      [binstr].pack('m').split("\n").join('')
    end

    def dec64(ascii)
      ascii.unpack('m').first
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
      msgary = [PROJ, br, RUBY_VERSION]
      msg = format('PROJECT = %s, BRANCH = %s, RUBY Ver = %s, ', *msgary)
      msg += format('DAEMON = %s, SERVER = %s, DATE = %s',*tagary)
      _git("tag -afm '#{msg}' '#{tag}'")
      tag
    end

    def _git(str)
      `cd #{__dir__};git #{str}`
    end
  end
end
