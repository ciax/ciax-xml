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
    def shell
      verbose(self.class,"Init/Shell(#@id)",2)
      Readline.completion_proc=proc{|word|
        (@cobj.valid_keys+@cobj.valid_pars).grep(/^#{word}/)
      }
      while line=readline(prompt)
        break if /^q/ === line
        begin
          exe(shell_input(line))
          puts shell_output
        rescue InvalidID
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

  class ShList < ExeList
    attr_reader :site
    def initialize(upper=Config.new)
      super()
      upper[:ldb]||=Loc::Db.new
      @cfg=Config.new(upper)
      @init_procs << proc{|exe| exe.cobj.lodom.add_group(:group_class =>SwSiteGrp)}
    end

    def shell(site)
      @site=site||@site
      begin
        self[@site].shell
      rescue SiteJump
        @site=$!.to_s
        retry
      end
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end

  class ShLayer < Hashx
    def initialize(cfg=Config.new)
      @cfg=type?(cfg,Config)
      @cfg[:ldb]||=Loc::Db.new
      @swlgrp=SwLayerGrp.new
    end

    def add_layer(layer)
      type?(layer,Module)
      str=layer.to_s.split(':').last
      id=str.downcase
      lst=(@cfg[id]||=layer::List.new(@cfg))
      @swlgrp.add_item(id,str+" mode")
      lst.init_procs << proc{|exe| exe.cobj.lodom.join_group(@swlgrp) }
      self[id]=lst
    end

    def shell(site)
      layer=keys.last
      begin
        self[layer][site].shell
      rescue SiteJump
        site=$!.to_s
        retry
      rescue LayerJump
        layer=$!.to_s
        retry
      end
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end
end
