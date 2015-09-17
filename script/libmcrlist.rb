#!/usr/bin/ruby
require "libmcrseq"
module CIAX
  module Mcr
    # Sequencer Layer List
    # @cfg[:db] associated site/layer should be set
    # @cfg should have [:jump_groups]
    class List < CIAX::List
      def initialize(proj,cfg)
        super(cfg)
        self['id']=proj
        verbose("Initialize [#{proj}]")
      end

      def to_v
        idx=1
        page=['<<< '+Msg.color("Active Macros [#{self['id']}]",2)+' >>>']
        @data.each{|id,seq|
          title="[#{idx}] (#{id})(by #{get_cid(seq['pid'])})"
          msg="#{seq['cid']} [#{seq['step']}/#{seq['total_steps']}]"
          msg << "(#{seq['stat']})"
          msg << optlist(seq['option'])
          page << Msg.item(title,msg)
          idx+=1
        }
        page.join("\n")
      end

      def ext_sv
        extend(Sv).ext_sv
      end

      def ext_shell
        extend(Shell).ext_shell
      end

      private
      # Getting command ID (ex. run:1)
      def get_cid(id)
        return 'user' if id == '0'
        get(id)['cid']
      end

      ### Server methods
      module Sv
        def ext_sv
          ext_file
          clean
          self
        end

        def interrupt
          @data.each{|id,seq|
            seq.exe(['interrupt'])
          }
        end

        # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
        def add(ent,pid='0')
          seq=Seq.new(ent,pid)
          seq.post_stat_procs << proc{upd}
          put(seq['id'],seq)
        end

        def clean
          @data.delete_if{|k,seq|
            ! (Seq === seq && seq.th_mcr.status)
          }
          upd
          self
        end
      end

      module Shell
        include CIAX::List::Shell
        class Jump < LongJump; end

        def ext_shell
          super(Jump)
          @cfg[:sub_list].ext_shell if @cfg.key?(:sub_list) # Limit self level
          @cfg[:jump_groups] << @jumpgrp
          @post_upd_procs << proc{
            verbose("Propagate List#upd -> JumpGrp#upd")
            @jumpgrp.number_item(@data.values.map{|seq| seq['id']})
          }
          self
        end

        def add(ent,pid='0')
          super.ext_shell
        end

        def get_exe(num)
          n=num.to_i-1
          par_err("Invalid ID") if n < 0 or n > @data.size
          @data[keys[n]]
        end

        def shell
          num=size.to_s
          begin
            get_exe(num).shell
          rescue Jump
            num=$!.to_s
            retry
          rescue InvalidID
            $opt.usage('(opt) [site]')
          end
        end
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('tenr')
      cfg=Config.new
      cfg[:jump_groups]=[]
      cfg[:sub_list]=Wat::List.new(cfg).sub_list #Take App List
      list=List.new(PROJ,cfg).ext_sv.ext_shell
      mobj=Remote::Index.new(cfg,{:dbi =>Db.new.get(PROJ)})
      mobj.add_rem.add_ext(Ext)
      cfg[:submcr_proc]=proc{|args,pid|
        ent=mobj.set_cmd(args)
        list.add(ent,pid)
      }
      begin
        mobj.set_cmd if ARGV.empty?
        ARGV.each{|cid|
          ent=mobj.set_cmd(cid.split(':'))
          list.add(ent)
        }
        list.shell
      rescue InvalidCMD
        $opt.usage('[cmd(:par)] ...')
      end
    end
  end
end
