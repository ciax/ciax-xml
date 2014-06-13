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

    def ext_shell(output={},&prompt_proc)
      # For Shell
      @output=output
      @prompt_proc=prompt_proc
      # Local(Long Jump) Commands (local handling commands on Client)
      shg=@cobj.lodom.add_group('caption'=>"Shell Command",'color'=>1)
      shg.add_dummy('^D,q',"Quit")
      shg.add_dummy('^C',"Interrupt")
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
    # '^D' gives exit break.
    # mode gives special break (loop returns mode).
    def shell(dmy=nil)
      verbose(self.class,"Init/Shell(#@id)",2)
      Readline.completion_proc=proc{|word|
        (@cobj.valid_keys+@cobj.valid_pars).grep(/^#{word}/)
      }
      while line=readline(prompt)
        break if /^q/ === line
        begin
          exe(shell_input(line))
          puts shell_output
        rescue
          puts $!.to_s
        end
      end
    end

    def readline(prompt)
      Readline.readline(prompt,true)
    rescue Interrupt
      'interrupt'
    end
  end
end
