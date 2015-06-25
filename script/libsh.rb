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
      verbose("Shell","Initialize [#{@id}]")
      @cobj.rem.hid.add_nil
      @cobj.loc.add_shell
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
      verbose("Shell","Shell(#@id)")
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
          warning("Shell",$!)
        end
        puts self['msg'].empty? ? @shell_output_proc.call : self['msg']
        verbose("Threads","#{Threadx.list}")
        verbose("Shell","Valid Commands #{@cobj.valid_keys}")
      }
    end
  end
end
