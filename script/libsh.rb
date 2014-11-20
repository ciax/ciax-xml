#!/usr/bin/ruby
require "libexe"
require "readline"

module CIAX
  # Provide Shell related modules
  # Add Shell Command (by Shell extention)
  module Shell
    def self.extended(obj)
      Msg.type?(obj,Exe)
    end

    def ext_shell
      # Local(Long Jump) Commands (local handling commands on Client)
      shg=@cobj.lodom.add_group('caption'=>"Shell Command",'color'=>1)
      shg.add_dummy('q',"Quit")
      shg.add_dummy('^D',"Interrupt")
      @cobj.hidgrp.add_item(nil)
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
    def shell(dmy=nil)
      verbose("Shell","Shell(#@id)")
      Readline.completion_proc=proc{|word|
        (@cobj.valid_keys+@cobj.valid_pars).grep(/^#{word}/)
      }
      loop{
        line=Readline.readline(prompt,true)||'interrupt'
        break if /^q/ === line
        cmds=line.split(';')
        cmds=[""] if cmds.empty?
        begin
          cmds.each{|token|
            exe(@shell_input_proc.call(token.split(' ')),'shell')
          }
        rescue UserError
        end
        puts @shell_output_proc.call
      }
    end
  end
end
