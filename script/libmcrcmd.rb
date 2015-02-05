#!/usr/bin/ruby
require "libmcrdb"
require "libextcmd"

module CIAX
  module Mcr
    class Command < Command
      attr_reader :cfg,:extgrp,:intgrp
      def add_ext
        @cfg[:depth]=0
        @extgrp=@svdom.add_group(:mod => Ext, :mobj => self)
        self
      end

      def ext_proc(&def_proc)
        @extgrp.set_proc(&def_proc)
        self
      end

      def add_int
        @intgrp=@svdom.add_group(:mod => Int)
        self
      end
    end

    module Int
      class Group < Group
        attr_reader :valid_pars
        def initialize(upper,crnt={})
          crnt[:group_id]='internal'
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
    end

    module Ext
      include CIAX::Ext
      class Entity < Entity
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
