#!/usr/bin/ruby
require "libstatus"
require "libcommand"
require "libmcrprt"

module CIAX
  module Mcr
    class Record < Datax
      attr_reader :crnt,:procs
      def initialize(cmd,label,procs=Procs.new)
        super('mcr')
        @base=Time.new.to_f
        self['id']=@base.to_i
        self['cmd']=cmd
        self['label']=label
        self['steps']=[]
        self['total']=0
        @procs=type?(procs,Procs)
        # shoud have [:setstat,:getstat,:exec,:submcr,:query]
      end

      def add_step(db,depth)
        @crnt=Step.new(db,@base,depth,@procs)
        @crnt.extend(Prt) unless $opt['r']
        self['steps'] << @crnt
        @crnt
      end

      def fin
        self['total']=Msg.elps_sec(@base)
      end
    end

    class Step < ExHash
      def initialize(db,base,depth=0,procs)
        self['time']=Msg.elps_sec(base)
        self['depth']=depth
        update(type?(db,Hash))
        @condition=delete('stat')
        @procs=type?(procs,Procs)
      end

      def exec
        if exec?
          @procs[:exec].call(self['site'],self['cmd'])
          self['result']='done'
        else
          self['result']='skip'
        end
      end

      def timeout?(&p) # Print Progress Proc
        #gives number or nil(if break)
        self['max']=self['retry']
        max = dryrun? ? 3 : self['max']
        max.to_i.times{|n|
          self['retry']=n
          return if ok?('pass','wait')
          refresh
          sleep 1
          p.call if p
        }
        self['result']='timeout'
      end

      def skip?
        ok?('skip','pass') && !dryrun?
      end

      def fail?
        ! ok?('pass','failed')
      end

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
      def title ; self['label']||self['cmd']; end
      def result ; "\n"+to_s; end
      def action ; "\n"; end

      private
      def ok?(t=nil,f=nil)
        cond=scan
        res=cond.all?{|h| h['upd'] && h['res']}
        self['conditions']=cond
        self['result']=(res ? t : f) if t || f
        res
      end

      def scan
        stats=sites.inject({}){|hash,site|
          hash[site]=@procs[:getstat].call(site)
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
          @procs[:getstat].call(site).refresh
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
        res=@procs[:query].(cmds,self['depth'])
        delete('option')
        res
      end
    end

    class Procs < Hash
      def initialize
        super
        default=proc{}
      end
    end
  end
end
