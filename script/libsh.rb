#!/usr/bin/env ruby
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
      def ext_local_shell
        @cobj.rem.sys.add_empty
        @cfg[:output] = @stat
        ___init_sh_procs
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
        str += @sv_stat.to_s
        str += @prompt_proc.call if @prompt_proc
        str + '>'
      end

      # * 'shell' is separated from 'ext_local_shell',
      #    because it will repeat being invoked and exit multiple times.
      # * '^D' gives interrupt
      def shell
        verbose { "Shell(#{@id})" }
        ___init_readline
        loop do
          line = ___input || break
          puts ___exe(___cmds(line)) || @shell_output_proc.call
        end
        @terminate_procs.inject(self) { |a, e| e.call(a) }
        Msg.msg('Quit Shell', 3)
      end

      private

      def ___init_sh_procs
        @shell_output_proc ||= proc do
          @sv_stat.msg.empty? ? @cfg[:output].to_s : @sv_stat.msg
        end
        @shell_input_procs = [] # proc takes args(Array)
      end

      def ___init_readline
        Readline.completion_proc = proc { |word|
          (@cobj.valid_keys + @cobj.valid_pars).grep(/^#{word}/)
        }
      end

      def ___input
        verbose { "Threads\n#{Threadx.list.view}" }
        verbose { "Valid Commands #{@cobj.valid_keys.inspect}" }
        inp = Readline.readline(prompt, true)
        /^q/ =~ inp ? nil : inp
      rescue Interrupt
        'interrupt'
      end

      def ___cmds(line)
        cmds = line.split(';')
        cmds = [''] if cmds.empty?
        cmds
      end

      def ___exe(cmds)
        cmds.each { |s| exe(___input_conv(s), 'shell') }
        nil
      rescue InvalidPAR
        show_err(@cobj.view_par)
      rescue UserError
        show_err(@cobj.view_dic)
      rescue ServerError
        show_err
      end

      def ___input_conv(token)
        @shell_input_procs.inject(token.split(' ')) do |args, proc|
          proc.call(args)
        end
      end
    end
  end
end
