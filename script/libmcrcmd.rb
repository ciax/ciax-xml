#!/usr/bin/ruby
require "libmcrdb"
require "libextcmd"

module CIAX
  module Mcr
    class Command < Command
      attr_reader :cfg,:extgrp,:intgrp
      def add_ext
        svc={:group_class =>ExtGrp,:entity_class=>ExtEntity,:mobj => self}
        @cfg[:depth]=0
        @extgrp=@svdom.add_group(svc)
        self
      end

      def add_int
        inc={:group_class =>IntGrp,:group_id =>'internal'}
        @intgrp=@svdom.add_group(inc)
        self
      end

      def ext_proc(&def_proc)
        @extgrp.set_proc(&def_proc)
        self
      end
    end

    class IntGrp < Group
      attr_reader :valid_pars
      def initialize(upper,crnt={})
        super
        @valid_pars=[]
        parlist={:parameters => [{:type => 'str',:list => @valid_pars,:default => nil}]}
        @cfg['caption']='Internal Commands'
        {
          "exec"=>"Command",
          "skip"=>"Execution",
          "drop"=>" Macro",
          "suppress"=>"and Memorize",
          "force"=>"Proceed",
          "pass"=>"Step",
          "ok"=>"for the message",
          "retry"=>"Checking",
        }.each{|id,cap|
          add_item(id,id.capitalize+" "+cap,parlist)
        }
      end
    end

    class ExtEntity < ExtEntity
      def initialize(upper,crnt={})
        super
        exp=[]
        @cfg[:body].each{|elem|
          elem["depth"]=@cfg[:depth]
          exp << elem
          next if elem["type"] != "mcr" || /true|1/ === elem["async"]
          exp+=@cfg[:mobj].set_cmd(elem["args"],{:depth => @cfg[:depth]+1}).cfg[:body]
        }
        @cfg[:body]=exp
      end
    end

    class ConfCmd < Config
      def initialize(name='mcr',proj=nil)
        super(name)
        self[:db]=Db.new.set(ENV['PROJ']||'ciax')
      end
    end

    if __FILE__ == $0
      GetOpts.new
      begin
        mobj=Command.new(ConfCmd.new).add_ext
        puts mobj.set_cmd(ARGV).cfg
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
