#!/usr/bin/ruby
require "liblist"
require "libmcrexe"

module CIAX
  module Mcr
    # List takes Command which could be shared with Man
    class List < List
      # @index: current element (1..@data.size)
      # initialize takes Command for generating submacro
      attr_accessor :index
      def initialize(cobj=nil)
        @cobj=type?(cobj||Command.new.add_extgrp,Command)
        super(Mcr,@cobj.cfg)
        @cfg[:dataname]='procs'
        @cfg[:valid_keys]=@valid_keys=[]
        @cfg["line_number"]=true
        self['id']=@cfg[:db]["id"]
        self['ver']=@cfg[:db]["version"]
        @post_upd_procs << proc{
          @valid_keys.replace(@data.keys)
          set_index
        }
        @cfg[:jump_groups] << @jumpgrp
        @index=0
        @lastsize=0
        @records={}
      end

      #convert the order number(Integer) to key (sid)
      def current_sid
        @data.keys[@index-1]
      end

      # return false if no change in @index
      def set_index(str=nil)
        n=str.to_i
        oidx=@index
        verbose('Index',"Data size #{@lastsize} -> #{@data.size}")
        if @data.size >= n && n > 0
          @index=n
          # Manual change
          return str.replace(current_sid)
        elsif @data.size > @lastsize
          # Increase mcr
          verbose('Index','increase')
          @index=@data.size
        elsif @index > @data.size
          # Decrease mcr
          verbose('Index','decrease')
          @index=@data.size
        end
        @lastsize=@data.size
        verbose('Index',"Index Changed #{oidx} -> #{@index}")
        false
      end

      def conv_cmd(args,list)
        # Internal command with sid
        args[1]=current_sid if list.key?(args[0])
        # Change current sid
        res=set_index(args[0]) ? [] : args
      end

      def output
        @records[current_sid]||self
      end

      def option
        (@data[current_sid]||{})['option']||{}
      end

      def to_v
        idx=1
        page=['<<< '+Msg.color('Active Macros',2)+' >>>']
        @data.each{|key,mst|
          title="[#{idx}](#{key})"
          msg="#{mst['cid']} [#{mst['step']}/#{mst['total_steps']}](#{mst['stat']})"
          page << Msg.item(title,msg)
          idx+=1
        }
        page.join("\n")
      end
    end

    class ClList < List
      def initialize(cobj=nil)
        super
        host=type?(@cfg['host']||'localhost',String)
        @post_upd_procs << proc{
          @data.keys.each{|sid|
            @records[sid]||=Record.new(self['id']).ext_http(host,sid)
            @records[sid].upd
          }
        }
        ext_http(host)
      end
    end

    class SvList < List
      def initialize(cobj=nil)
        super
        @tgrp=ThreadGroup.new
        ext_file
        clean
      end

      # Used by Man
      def add_ent(ent)
        ssh=Seq.new(type?(ent,Entity).cfg)
        ssh.post_stat_procs << proc{upd}
        ssh.post_mcr_procs << proc{|s|
          del_seq(s.id)
          clean
        }
        # JumpGroup is set to Domain
        @jumpgrp.add_item(ssh.id,ssh['cid'])
        @cfg[:jump_groups].each{|grp|
          ssh.cobj.lodom.join_group(grp)
        }
        # Set input alias as number
        ssh.shell_input_proc=proc{|args|
          set_index(args[0])
          args
        }
        set(ssh.id,ssh)
        @records[ssh.id]=ssh.record
        ssh.fork(@tgrp)
        self
      end

      # Used by List
      def add_seq(args)
        add_ent(@cobj.set_cmd(args))
      end

      def del_seq(id)
        @data.delete(id)
        @records.delete(id)
        @jumpgrp.del_item(id)
        self
      end

      def clean
        @data.keys.each{|id|
          unless @tgrp.list.any?{|t| id == t[:sid]}
            del_seq(id)
          end
        }
        upd
      end

      def interrupt
        @tgrp.list.each{|t|
          t.raise(Interrupt)
        }
        upd
      end
    end

    class Jump < LongJump; end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('tenr')
      begin
        list=SvList.new
        ARGV.each{|cid|
          list.add_seq(cid.split(':'))
        }.empty? && list.add_seq([])
        list.shell
      rescue InvalidCMD
        $opt.usage('[cmd(:par)] ...')
      end
    end
  end
end
