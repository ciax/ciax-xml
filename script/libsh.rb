#!/usr/bin/ruby
require "libexe"
require "readline"
require "libthreadx"

module CIAX
  # Provide Shell related modules
  # Add Shell Command (by Shell extention)
  module Shell
    def self.extended(obj)
      Msg.type?(obj,Exe)
    end

    # Separate initialize part because shell() could be called multiple times
    def ext_shell
      @shell_input_procs=[] #proc takes args(Array)
      @shell_output_proc=proc{ @cfg[:output].to_s }
      @prompt_proc=proc{ @sv_stat.to_s }
      @cobj.loc.add_shell
      @cobj.loc.add_jump #@cfg[:jump_groups] should be set
      Thread.current['name']='Main'
      self
    end

    # Convert Shell input from "x=n" to "set x n"
    def input_conv_set
      @shell_input_procs << proc{|args|
        if args[0] && args[0].include?('=')
          ['set']+args.shift.split('=')+args
        else
          args
        end
      }
      self
    end

    # Convert Shell input from number to string
    def input_conv_num(cmdlist=[])
      @shell_input_procs << proc{|args|
        n=cmdlist.include?(args[0]) ? 1 : 0
        args[n]=yield(args[n].to_i) if args[n] && /^[0-9]/ =~ args[n]
        args
      }
      self
    end

    def prompt
      str="#@layer:#@id"
      str+="(#@mode)" if @mode
      str+=@prompt_proc.call if @prompt_proc
      str+'>'
    end

    # invoked many times.
    # '^D' gives interrupt
    # mode gives special break (loop returns mode).
    def shell(dmy=nil) # dmy: compatibility with List#shell()
      verbose("Shell(#@id)")
      Readline.completion_proc=proc{|word|
        (@cobj.valid_keys+@cobj.valid_pars).grep(/^#{word}/)
      }
      loop{
        begin
          line=Readline.readline(prompt,true)||'interrupt'
        rescue Interrupt
          line='interrupt'
        end
        break if /^q/ === line
        cmds=line.split(';')
        cmds=[""] if cmds.empty?
        begin
          cmds.each{|token|
            exe(convert(token),'shell')
          }
        rescue UserError
        rescue ServerError
          warning($!)
        end
        puts @sv_stat.msg.empty? ? @shell_output_proc.call : @sv_stat.msg
        verbose("Threads","#{Threadx.list}")
        verbose("Valid Commands #{@cobj.valid_keys}")
      }
      @terminate_procs.inject(self){|obj,proc| proc.call(obj)}
      Msg.msg("Quit Shell",3)
    end

    private
    def convert(token)
      @shell_input_procs.inject(token.split(' ')){|args,proc|
        proc.call(args)
      }
    end
  end
end
