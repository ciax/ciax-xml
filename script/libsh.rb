#!/usr/bin/ruby
require 'readline'
require 'libthreadx'

module CIAX
  # Device Execution Engine
  class Exe
    # Provide Shell related modules
    # Add Shell Command (by Shell extension)
    module Shell
      def self.extended(obj)
        Msg.type?(obj, Exe)
      end

      # Separate initialize part because shell() could be called multiple times
      def ext_shell
        _init_procs_
        @cobj.loc.add_shell
        @cobj.loc.add_jump
        self
      end

      # Convert Shell input from "x=n" to "set x n"
      def input_conv_set
        @shell_input_procs << proc do |args|
          if args[0] && args[0].include?('=')
            ['set'] + args.shift.split('=') + args
          else
            args
          end
        end
        self
      end

      # Substitute command from number to value
      def input_conv_num
        @shell_input_procs << proc do |args|
          args[0] = yield(args[0].to_i) if /^[0-9]+$/ =~ args[0]
          args
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
      def shell
        verbose { "Shell(#{@id})" }
        _init_readline_
        loop do
          line = _input_ || break
          _exe_(_cmds_(line))
          puts @shell_output_proc.call
        end
        @terminate_procs.inject(self) { |a, e| e.call(a) }
        Msg.msg('Quit Shell', 3)
      end

      private

      def _init_procs_
        @shell_input_procs = [] # proc takes args(Array)
        @shell_output_proc ||= proc do
          if @sv_stat.msg.empty?
            @cfg[:output].to_s
          else
            @sv_stat.msg
          end
        end
        @prompt_proc = proc { @sv_stat.to_s }
      end

      def _init_readline_
        Readline.completion_proc = proc { |word|
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
        cmds.each { |s| exe(_input_conv_(s), 'shell') }
      rescue UserError
        nil
      rescue ServerError
        show_err
      end

      def _input_conv_(token)
        @shell_input_procs.inject(token.split(' ')) do |args, proc|
          proc.call(args)
        end
      end
    end
  end
end
