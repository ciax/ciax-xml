#!/usr/bin/ruby
require "libmcrdb"
require "libextcmd"

module CIAX
  module Mcr
    class Command < Command
      attr_reader :cfg,:intgrp
      def add_extgrp
        @cfg[:depth]=1
        @cfg[:mobj]=self
        @cfg[:db]||=Db.new.get(ENV['PROJ']||'ciax')
        super(Ext)
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
      class Entity < Ext::Entity
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

    if __FILE__ == $0
      GetOpts.new
      begin
        ment=Command.new.add_extgrp.set_cmd(ARGV)
        puts ment.cfg
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
