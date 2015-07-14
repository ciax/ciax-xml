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
    def ext_shell(als=nil)
      verbose("#{self.class}:Initialize [#{@id}]")
      @shell_input_proc=proc{|args|
        if (cmd=args.first) && cmd.include?('=')
          args=['set']+cmd.split('=')
        end
        args
      }
      @shell_output_proc=proc{ @cfg[:output] }
      @prompt_proc=proc{ @site_stat.to_s }
      @cobj.loc.add_shell
      @cobj.loc.add_jump #@cfg[:jump_groups] should be set
      Thread.current['name']='Main'
      @alias=als||@id
      self
    end

    def prompt
      str="#@layer:#@alias"
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
            exe(@shell_input_proc.call(token.split(' ')),'shell')
          }
        rescue UserError
        rescue ServerError
          warning($!)
        end
        puts self['msg'].empty? ? @shell_output_proc.call : self['msg']
        verbose("Threads","#{Threadx.list}")
        verbose("Valid Commands #{@cobj.valid_keys}")
      }
    end
  end
end
