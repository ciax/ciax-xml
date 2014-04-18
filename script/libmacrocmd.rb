#!/usr/bin/ruby
require "libmcrdb"
require "librecord"
require "libappsh"


module CIAX
  module Mcr
    class Command < Command
      attr_reader :extgrp,:intgrp
      def initialize(upper)
        super
        svc={:group_class =>ExtGrp,:mobj => self}
        svc[:int_grp]=IntGrp.new(@cfg).def_proc
        @extgrp=@svdom.add_group(svc)
      end

      def ext_proc(&def_proc)
        @extgrp.set_proc(&def_proc)
      end

      def add_int(crnt={})
        crnt[:group_class]=IntGrp
        @intgrp=@svdom.add_group(crnt)
      end
    end

    class IntGrp < Group
      def initialize(upper,crnt={})
        super
        @cfg['caption']='Internal Commands'
        @procs={}
        {
          "exec"=>["Command",proc{'EXEC'}],
          "skip"=>["Execution",proc{raise(Skip)}],
          "drop"=>[" Macro",proc{raise(Interlock)}],
          "suppress"=>["and Memorize",proc{'SUP'}],
          "force"=>["Proceed",proc{'FORCE'}],
          "pass"=>["Step",proc{nil}],
          "ok"=>["for the message",proc{nil}],
          "retry"=>["Checking",proc{raise(Retry)}]
        }.each{|id,a|
          add_item(id,id.capitalize+" "+a[0])
          @procs[id]=a[1]
        }
      end

      def def_proc
        @procs.each{|id,prc|
          self[id].set_proc(&prc)
        }
        self
      end
    end

    if __FILE__ == $0
      GetOpts.new
      begin
        cfg=Config.new
        cfg[:db]=Db.new.set('ciax')
        mobj=Command.new(cfg)
        puts mobj.set_cmd(ARGV).cfg[:body].extend(Enumx).to_s
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
