#!/usr/bin/ruby
require "libmsg"
require "socket"
require "readline"
require "libextcmd"
require "libupdate"
require "libexe"

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
      @pdb={'layer' => "%s:",'id' => nil}.update(pdb)
      # Local(Long Jump) Commands (local handling commands on Client)
      shg=@cobj['lo'].add_group('sh',"Shell Command",2,1)
      shg.add_dummy('^D,q',"Quit")
      shg.add_dummy('^C',"Interrupt")
      self
    end

    def to_s
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
        while line=Readline.readline(to_s,true)
          break if /^q/ === line
          exe(shell_input(line))
          puts shell_output
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
    def initialize
      super
      @swsgrp=Group.new({'caption'=>'Switch Sites','color'=>5,'column'=>2})
      @swsgrp.share[:def_proc]=proc{|item| throw(:sw_site,item.id)}
      @init_proc << proc{|exe|
        exe.cobj['lo']['sws']=@swsgrp
      }
    end

    def update_items(list)
      type?(list,Hash)
      @swsgrp.update_items(list)
      self
    end

    def shell(current)
      true while current=catch(:sw_site){ self[current].shell }
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end

  class ShLayer < Hashx
    def initialize
      @swlgrp=Group.new({'caption'=>"Switch Layer",'color'=>5,'column'=>5})
      @swlgrp.share[:def_proc]=proc{|item| throw(:sw_layer,item.id) }
    end

    def add(layer,shlist)
      Msg.type?(shlist,ShList)
      @swlgrp.add_item(layer,layer.capitalize+" mode")
      shlist.init_proc << proc{|exe|
        exe.cobj['lo']['swl']=@swlgrp
      }
      self[layer]=shlist
    end

    def shell(id)
      current=keys.last
      true while current=catch(:sw_layer){self[current].shell(id)}
    end
  end
end
