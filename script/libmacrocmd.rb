#!/usr/bin/ruby
require "libmcrdb"
require "libextcmd"

module CIAX
  module Mcr
    class Command < Command
      attr_reader :cfg,:extgrp,:intgrp
      def initialize(upper)
        super
        svc={:group_class =>ExtGrp,:entity_class=>ExtEntity,:mobj => self}
        @extgrp=@svdom.add_group(svc)
        inc={:group_class =>IntGrp,:group_id =>'internal'}
        @intgrp=@svdom.add_group(inc)
        @cfg[:depth]=0
      end

      def ext_proc(&def_proc)
        @extgrp.set_proc(&def_proc)
      end
    end

    class IntGrp < Group
      attr_reader :parameter
      def initialize(upper,crnt={})
        super
        @parameter={:type => 'num',:list => [],:default => nil}
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
          add_item(id,id.capitalize+" "+cap,{:parameter => [@parameter]})
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

    if __FILE__ == $0
      GetOpts.new
      begin
        cfg=Config.new
        cfg[:db]=Db.new.set('ciax')
        mobj=Command.new(cfg)
        puts mobj.set_cmd(ARGV).cfg
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
