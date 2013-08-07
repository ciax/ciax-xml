#!/usr/bin/ruby
require "libstatus"
require "libcommand"

module CIAX
  module Mcr
    class Record < Datax
      CmdOpt={
        "Exec Command"=>proc{true},
        "Skip Execution"=>proc{false},
        "Done Macro"=>proc{true},
        "Force Proceed"=>proc{false},
        "Retry Checking"=>proc{raise(Retry)}
      }

      # Level [0] Step, [1] Record & Item, [2] Group, [3] Domain, [4] Command
      def initialize(item,msh={},valid_keys=[],shary=[])
        super('record',[],'steps')
        self['id']=self['time'].to_i
        self['cid']=item[:cid]
        self['label']=item[:label]
        @share={:msh => msh,:depth => 0,:running => [], :cmds => {}, :cmdlist =>{}, :cmdproc =>{}}
        @share[:valid_keys]=valid_keys.clear
        @share[:levelshare]=type?(shary,ShareAry) #[:setstat,:getstat,:exec,:submcr,:query,:show]
        CmdOpt.each{|str,v|
          k=str[0].downcase
          @share[:cmds][k]=str.split(' ').first
          @share[:cmdlist][k]=str
          @share[:cmdproc][k]=v
        }
      end

      def start
        @share[:msh]['stat']='run'
        @share[:levelshare][:show].call(self)
      end

      def add_step(db) # returns nil or submacro db
        step=Step.new(db,self['time'],@share)
        @data << step
        case db['type']
        when 'goal'
          step.skip?
        when 'check'
          step.fail?
        when 'wait'
          step.timeout?
        when 'exec'
          step.exec
        when 'mcr'
          step.submcr
        end
      end

      def push
        @share[:depth]+=1
      end

      def pop
        @share[:depth]-=1
      end

      def done
        fin('done')
      end

      def error
        fin('error')
      end

      def interrupt
        warn("\nInterrupt Issued to #{@share[:running]}]")
        @share[:running].each{|site|
          @share[:levelshare][:exec].call(site,['interrupt'])
        }
        fin('interrupted')
      end

      private
      def fin(str)
        @share[:msh]['stat']=str
        @share[:levelshare][:show].call(str+"\n")
        self['result']=str
        self['total']=Msg.elps_sec(self['time'])
        @share[:valid_keys].clear
        @share[:running].clear
        self
      end
    end

    class Step < ExHash
      def initialize(db,base,share)
        @share=share
        self['time']=Msg.elps_sec(base)
        self['depth']=@share[:depth]
        update(type?(db,Hash))
        @condition=delete('stat')
      end

      # Execution section
      def submcr
        show to_s
        item=@share[:levelshare][:submcr].call(self['cmd'])
        if /true|1/ === self['async']
          @share[:levelshare][:asymcr].call(item)
          return
        end
        item
      end

      def exec
        show title
        #array of site for interrupt
        @share[:running] << self['site']
        if exec?
          @share[:levelshare][:exec].call(self['site'],self['cmd'])
          self['result']='done'
        else
          self['result']='skip'
        end
        show result
        nil
      end

      # Conditional judgment section
      def timeout?
        show title
        self['max']=self['retry']
        max = dryrun? ? 1 : self['max']
        res=max.to_i.times{|n| #gives number or nil(if break)
          self['retry']=n
          break if ok?('pass','wait')
          refresh
          sleep 1
          show '.'
        }
        self['result']= res ? 'timeout' : 'pass'
        show result
        raise(Interlock) if res && done?
      end

      def skip?
        show title
        res=ok?('skip','pass') && !dryrun?
        show result
        raise(Skip) if res
      end

      def fail?
        show title
        res=! ok?('pass','failed')
        show result
        raise(Interlock) if res && done?
      end

      private
      # Interactive section
      def exec?
        return false if dryrun?
        return true if $opt['n']
        query(['e','s'])
      end

      def done?
        return true if $opt['n']
        query(['d','f','r'])
      end

      def dryrun?
        ! ['e','s','t'].any?{|i| $opt[i]} && self['action']='dryrun'
      end

      # Display section
      def title ; self['label']||self['cmd']; end
      def result ; "\n"+to_s; end
      def show(msg=self) # Print Progress Proc
        @share[:levelshare][:show].call(msg)
        self
      end

      # Sub methods
      def ok?(t=nil,f=nil)
        cond=scan
        res=cond.all?{|h| h['upd'] && h['res']}
        self['conditions']=cond
        self['result']=(res ? t : f) if t || f
        res
      end

      def scan
        stats=sites.inject({}){|hash,site|
          hash[site]=@share[:levelshare][:getstat].call(site)
          hash
        }
        @condition.map{|h|
          cond={}
          site=cond['site']=h['site']
          var=cond['var']=h['var']
          stat=stats[site]
          if cond['upd']=stat.update?
            inv=cond['inv']=h['inv']
            cmp=cond['cmp']=h['val']
            act=stat['msg'][var]||stat.data[var]
            verbose("McrStep","site=#{site},var=#{var},inv=#{inv},cmp=#{cmp},act=#{act}")
            next unless act
            cond['act']=act
            cond['res']=match?(act,cmp,cond['inv'])
          end
          cond
        }
      end

      def refresh
        sites.each{|site|
          @share[:levelshare][:getstat].call(site).refresh
        }
      end

      def sites
        @condition.map{|h| h['site']}.uniq
      end

      def match?(act,cmp,inv)
        i=(/true|1/ === inv)
        if /[a-zA-Z]/ === cmp
          (/#{cmp}/ === act) ^ i
        else
          (cmp == act) ^ i
        end
      end

      def query(cmds)
        vk=@share[:valid_keys].replace(cmds)
        cdb=@share[:cmds]
        msg='['+vk.map{|k| cdb[k]}.join('/')+']?'
        msh=@share[:msh]
        msh['stat']='query'
        msh['opt']=msg
        begin
          @share[:levelshare][:query].call(item(msg,5))
          res=msh[:query]
        end until vk.include?(res)
        msh['opt']=nil
        msh['stat']='run'
        vk.clear
        self['action']=cdb[res].downcase
        @share[:cmdproc][res].call
      end
    end
  end
end

