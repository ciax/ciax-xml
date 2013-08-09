#!/usr/bin/ruby
require "libstatus"
require "libcommand"
require "libmcrprt"

module CIAX
  module Mcr
    Dryrun=1
    class Record < Datax
      # Level [0] Step, [1] Record & Item, [2] Group, [3] Domain, [4] Command
      def initialize(item)
        super('record',[],'steps')
        #[:stat_proc,:exec_proc,:submcr_proc,:query,:show_proc]
        @shary=type?(item.shary,ShareAry)
        self['id']=self['time'].to_i.to_s
        self['cid']=item[:cid]
        self['label']=item[:label]
        @depth=0
        extend PrtRecord unless $opt['r']
        ext_file(self['id'])
      end

      def start
        sets('run')
        @shary[:show_proc].call(self)
      end

      def add_step(db) # returns nil or submacro db
        step=Step.new(db,self,@depth,@shary)
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
        @depth+=1
      end

      def pop
        @depth-=1
      end

      def sets(str,opt=nil)
        @shary[:msh]['stat']=str
        @shary[:msh]['opt']=opt
        self['stat']=str
        if opt
          self['option']=opt
        else
          delete('option')
        end
        save
      end

      def finish(str='complete')
        @shary[:show_proc].call(str+"\n")
        self['result']=str
        self['total']=Msg.elps_sec(self['time'])
        @shary[:valid_keys].clear
        @shary[:running].clear
        sets('done')
        self
      end

      def error
        finish('error')
      end

      def interrupt
        warn("\nInterrupt Issued to #{@shary[:running]}]")
        @shary[:running].each{|site|
          @shary[:exec_proc].call(site,['interrupt'])
        }
        finish('interrupted')
      end
    end

    class Step < Hashx
      def initialize(db,record,depth,shary)
        update db
        @record=record
        @shary=shary
        self['time']=Msg.elps_sec(record['time'])
        self['depth']=depth
        @condition=delete('stat')
        extend PrtStep unless $opt['r']
      end

      # Execution section
      def submcr
        show to_s
        item=@shary[:submcr_proc].call(self['cmd'])
        if /true|1/ === self['async']
          @shary[:def_proc].call(item)
          return
        end
        item
      end

      def exec
        show title
        #array of site for interrupt
        @shary[:running] << self['site']
        if exec?
          @shary[:exec_proc].call(self['site'],self['cmd'])
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
        max = dryrun? ? Dryrun : self['max']
        res=max.to_i.times{|n| #gives number or nil(if break)
          self['retry']=n
          break if ok?('pass','wait')
          @record.save
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
      def body(msg); msg; end
      def show(msg=self) # Print Progress Proc
        @shary[:show_proc].call(msg)
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
          hash[site]=@shary[:stat_proc].call(site)
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
          @shary[:stat_proc].call(site).refresh
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
        vk=@shary[:valid_keys].replace(cmds)
        cdb=@shary[:cmds]
        msg='['+vk.map{|k| cdb[k]}.join('/')+']?'
        @record.sets('query',msg)
        begin
          res=@shary[:query_proc].call(body(msg))
        end until vk.include?(res)
        @record.sets('run')
        vk.clear
        self['action']=cdb[res].downcase
        @shary[:cmdproc][res].call
      end
    end
  end
end

