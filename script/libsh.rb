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
    def ext_shell(output={},pdb={})
      # For Shell
      @output=output
      @pdb={'eid' => nil}.update(pdb)
      # Local(Long Jump) Commands (local handling commands on Client)
      shg=@cobj['lo'].add_group('sh',"Shell Command",2,1)
      shg.add_dummy('^D,q',"Quit")
      shg.add_dummy('^C',"Interrupt")
      self
    end

    def prompt
      str=''
      @pdb.each{|k,fmt|
        next unless v=self[k]
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
      begin
        while line=Readline.readline(prompt,true)
          break if /^q/ === line
          exe(shell_input(line))
          puts shell_output
#          Thread.list.each{|t| puts t[:name]}
        end
      rescue Interrupt
        exe(['interrupt'])
        puts self['msg']
        retry
      rescue InvalidID
        puts $!.to_s
        retry
      end
    end
  end

  class ShList < ExeList
    attr_reader :site
    def initialize
      super
      @swsgrp=Group.new({'caption'=>'Switch Sites','color'=>5,'column'=>2})
      @swsgrp.set[:def_proc]=proc{|item| raise(SwSite,item[:cid])}
      @init_proc << proc{|exe|
        exe.cobj['lo']['sws']=@swsgrp
      }
    end

    def update_items(list)
      type?(list,Hash)
      @swsgrp.update_items(list)
      self
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
    def initialize
      @swlgrp=Group.new({'caption'=>"Switch Layer",'color'=>5,'column'=>5})
      @swlgrp.set[:def_proc]=proc{|item| raise(SwLayer,item[:cid]) }
    end

    def add_layer(layer,lst)
      @swlgrp.add_item(layer,layer.capitalize+" mode")
      lst.init_proc << proc{|exe| exe.cobj['lo']['swl']=@swlgrp }
      self[layer]=lst
    end

    def shell(site)
      layer=keys.first
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
