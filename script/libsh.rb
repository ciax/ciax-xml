#!/usr/bin/ruby
require 'libexe'
require 'readline'
require 'libthreadx'

module CIAX
  # Provide Shell related modules
  # Add Shell Command (by Shell extention)
  module Shell
    def self.extended(obj)
      Msg.type?(obj, Exe)
    end

    # Separate initialize part because shell() could be called multiple times
    def ext_shell
      @shell_input_procs = [] # proc takes args(Array)
      @shell_output_proc = proc { @cfg[:output].to_s }
      @prompt_proc = proc { @sv_stat.to_s }
      @cobj.loc.add_shell
      @cobj.loc.add_jump
      Thread.current['name'] = 'Main'
      self
    end

    # Convert Shell input from "x=n" to "set x n"
    def input_conv_set
      @shell_input_procs << proc do|args|
        if args[0] && args[0].include?('=')
          ['set'] + args.shift.split('=') + args
        else
          args
        end
      end
      self
    end

    # Substitute each element from number to value stored in cmdlist
    # number range is be > 0 ('0' won't be converted)
    def input_conv_num
      @shell_input_procs << proc do|args|
        args.map { |e| (/^[0-9]+$/ =~ e) ? yield(e.to_i) : e }
      end
      self
    end

    def prompt
      str = "#{@layer}:#{@id}"
      str += "(#{@mode})" if @mode
      str += @prompt_proc.call if @prompt_proc
      str + '>'
    end

    # * 'shell' is separated from 'ext_shell',
    #    because it will repeat being invoked and exit multiple times.
    # * '^D' gives interrupt
    # * 'exe' returns String or nil
    #    if 'exe' returns nil, @cfg[:output] (@shell_output_proc) is shown.
    def shell
      verbose { "Shell(#{@id})" }
      _init_readline_
      loop do
        line = _input_ || break
        _exe_(_cmds_(line))
        puts @sv_stat.msg.empty? ? @shell_output_proc.call : @sv_stat.msg
      end
      @terminate_procs.inject(self) { |a, e| e.call(a) }
      Msg.msg('Quit Shell', 3)
    end

    private

    def _init_readline_
      Readline.completion_proc = proc {|word|
        (@cobj.valid_keys + @cobj.valid_pars).grep(/^#{word}/)
      }
    end

    def _input_
      verbose { "Threads\n#{Threadx.list}" }
      verbose { "Valid Commands #{@cobj.valid_keys}" }
      inp = Readline.readline(prompt, true) || 'interrupt'
      /^q/ =~ inp ? nil : inp
    rescue Interrupt
      'interrupt'
    end

    def _cmds_(line)
      cmds = line.split(';')
      cmds = [''] if cmds.empty?
      cmds
    end

    def _exe_(cmds)
      cmds.each { |s| exe(_conv_(s), 'shell') }
    rescue UserError
      nil
    rescue ServerError
      warning($ERROR_INFO)
    end

    def _conv_(token)
      @shell_input_procs.inject(token.split(' ')) do|args, proc|
        proc.call(args)
      end
    end
  end
end
