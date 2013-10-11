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
      @pdb={'layer' => "%s:",'id' => nil}.update(pdb)
      @pstat=pstat||self
      # Local(Long Jump) Commands (local handling commands on Client)
      shg=@cobj['lo'].add_group('sh',{'caption'=>"Shell Command",'color'=>1})
      shg.add_dummy('^D,q',"Quit")
      shg.add_dummy('^C',"Interrupt")
      self
    end

    def prompt
      str=''
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
      verbose(self.class,"Init/Shell(#{self['id']})",2)
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
      @cfg=Config.new(upper)
      @cfg[:ldb]||=Loc::Db.new
      @init_procs << proc{|exe| exe.cobj['lo'].add_group('sws',{},SiteGrp)}
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
      lst=layer::List.new(@cfg)
      str=layer.to_s.split(':').last
      id=str.downcase
      @swlgrp.add_item(id,{:label =>str+" mode"})
      lst.init_procs << proc{|exe| exe.cobj['lo'].join('swl',@swlgrp) }
      @cfg[id]=lst
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
