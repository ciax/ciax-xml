#!/usr/bin/ruby
require "libexe"
require "readline"

# Provide Shell related modules
# Add Shell Command (by Shell extention)

module CIAX
  module Shell
    def self.extended(obj)
      Msg.type?(obj,Exe)
    end

    # Prompt Db : { key => format(str), key => conv_db(hash), key => nil(status) }
    attr_reader :pdb
    def ext_shell(output={},pdb={},pstat=nil)
      # For Shell
      @output=output
      @pdb=pdb
      @pstat=pstat||self
      # Local(Long Jump) Commands (local handling commands on Client)
      shg=@cobj.lodom.add_group('caption'=>"Shell Command",'color'=>1)
      shg.add_dummy('^D,q',"Quit")
      shg.add_dummy('^C',"Interrupt")
      self
    end

    def prompt
      str="#@layer:#@id"
      @pdb.each{|k,fmt|
        next unless v=@pstat[k]
        case fmt
        when String
          str << fmt % v
        when Hash
          str << fmt[v]
        else
          str << v
        end
      }
      str+'>'
    end

    # invoked many times
    # '^D' gives exit break
    # mode gives special break (loop returns mode)
    def shell
      verbose(self.class,"Init/Shell(#@id)",2)
      Readline.completion_proc=proc{|word|
        @cobj.valid_keys.grep(/^#{word}/)
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
      @init_procs << proc{|exe| exe.cobj.lodom.add_group(:group_class =>SiteGrp)}
    end

    def shell(site)
      @site=site||@site
      begin
        self[@site].shell
      rescue SwSite
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
      @swlgrp=LayerGrp.new
    end

    def add_layer(layer)
      type?(layer,Module)
      str=layer.to_s.split(':').last
      id=str.downcase
      lst=(@cfg[id]||=layer::List.new(@cfg))
      @swlgrp.add_item(id,{:label =>str+" mode"})
      lst.init_procs << proc{|exe| exe.cobj.lodom.join_group(@swlgrp) }
      self[id]=lst
    end

    def shell(site)
      layer=keys.last
      begin
        self[layer][site].shell
      rescue SwSite
        site=$!.to_s
        retry
      rescue SwLayer
        layer=$!.to_s
        retry
      end
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end
end
