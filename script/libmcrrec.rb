#!/usr/bin/ruby
require "libstatus"
require "libcommand"


module CIAX
  module Mcr
    class Record < Datax
      attr_accessor :depth
      def initialize(cmd,label,valid_keys=[],procary=ProcAry.new)
        super('record',[],'steps')
        self['id']=self['time'].to_i
        self['cmd']=cmd
        self['label']=label
        @valid_keys=valid_keys.clear
        @procary=type?(procary,ProcAry) #[:setstat,:getstat,:exec,:submcr,:query,:show]
        @executing=[] #array of site for interrupt
        @depth=0
        @procary[:setstat].call('run')
      end

      def add_step(db) # returns nil or submacro db
        step=Step.new(db,self['time'],@depth,@valid_keys,@executing,@procary)
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

      def done
        fin('done')
      end

      def error
        fin('error')
      end

      def interrupt
        warn("\nInterrupt Issued to #{@executing}")
        @executing.each{|site|
          @procary[:exec].call(site,['interrupt'])
        }
        result('interrupted')
      end

      private
      def fin(str)
        @procary[:setstat].call(str)
        @procary[:show].call(str+"\n")
        self['result']=str
        self['total']=Msg.elps_sec(self['time'])
        @valid_keys.clear
        @executing.clear
        self
      end
    end

    class Step < ExHash
      def initialize(db,base,depth=0,valid_keys,executing,procary)
        self['time']=Msg.elps_sec(base)
        self['depth']=depth
        update(type?(db,Hash))
        @condition=delete('stat')
        @valid_keys=valid_keys
        @procary=type?(procary,ProcAry)
        @executing=type?(executing,Array)
      end

      # Execution section
      def submcr
        show
        item=@procary[:submcr].call(self['cmd'])
        if /true|1/ === self['async']
          @procary[:asymcr].call(item)
          return
        end
        item
      end

      def exec
        show
        @executing << self['site']
        if exec?
          @procary[:exec].call(self['site'],self['cmd'])
          self['result']='done'
        else
          self['result']='skip'
        end
        show
        nil
      end

      # Conditional judgment section
      def timeout?
        show
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
        show
        raise(Interlock) if res && done?
      end

      def skip?
        show
        res=ok?('skip','pass') && !dryrun?
        show
        raise(Skip) if res
      end

      def fail?
        show
        res=! ok?('pass','failed')
        show
        raise(Interlock) if res && done?
      end

      private
      # Interactive section
      def exec?
        return false if dryrun?
        while ! $opt['n']
          case query(['Exec','Skip'])
          when /^E/i
            break
          when /^S/i
            self['action']='skip'
            return false
          end
        end
        self['action']='exec'
      end

      def done?
        return true if $opt['n']
        loop{
          case query(['Done','Force','Retry'])
          when /^D/i
            self['action']='done'
            return true
          when /^F/i
            self['action']='forced'
            return false
          when /^R/i
            self['action']='retry'
            raise(Retry)
          end
        }
      end

      def dryrun?
        ! ['e','s','t'].any?{|i| $opt[i]} && self['action']='dryrun'
      end

      # Display section
      def show_title ; self['label']||self['cmd']; end
      def show_result ; "\n"+to_s; end
      def show_action ; "\n"; end
      def show(msg=self) # Print Progress Proc
        @procary[:show].call(msg)
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
          hash[site]=@procary[:getstat].call(site)
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
          @procary[:getstat].call(site).refresh
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
        self['option']=cmds
        @valid_keys.replace(cmds.map{|s| s[0].downcase})
        @procary[:setstat].call('query')
        res=@procary[:query].call(self)
        @procary[:setstat].call('run')
        @valid_keys.clear
        delete('option')
        res
      end
    end
  end
end

