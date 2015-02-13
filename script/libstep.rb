#!/usr/bin/ruby
require "libmcrprt"

module CIAX
  module Mcr
    # Element of Record
    class Step < Upd
      include PrtShare
      def initialize(db,cfg)
        super()
        update db
        self['depth']=db['depth']
        #[:stat_proc,:exec_proc,:submcr_proc,:query,:show_proc]
        @cfg=cfg
        @condition=delete('stat')
        @break=nil
      end

      # Conditional judgment section
      def timeout?
        itv=($opt['m'] && ($opt['e'] || $opt['s']))? 1 : 0
        show title(self)
        max=self['max']=self['retry']
        res=max.to_i.times{|n| #gives number or nil(if break)
          self['retry']=n
          break if condition_ok?
          sleep itv
          yield
          post_upd
        }
        self['result']= res ? 'timeout' : 'pass'
        upd
        res
      end

      def ok?
        show title(self)
        upd
        'ok'
      end

      def skip?
        show title(self)
        res=condition_ok?('skip','pass')
        upd
        res
      end

      def fail?
        show title(self)
        res=! condition_ok?('pass','failed')
        upd
        res
      end

      # Interactive section
      def exec?
        show title(self)
        res= !dryrun?
        self['result']= res ? 'exec' : 'skip'
        upd
        res
      end

      # Execution section
      def async?
        show title(self)
        res=(/true|1/ === self['async'])
        self['result']= res ? 'forked' : 'entering'
        upd
        res
      end

      # Display section
      def to_v
        title(self)+result(self)
      end

      private
      def upd_core
        show result(self)
      end

      def show(msg)
        print msg if Msg.fg?
      end

      def dryrun?
        ! $opt['m'] && self['action']='dryrun'
      end

      # Sub methods
      def condition_ok?(t=nil,f=nil)
        stats=scan
        conds=@condition.map{|h|
          cond={}
          site=cond['site']=h['site']
          var=cond['var']=h['var']
          stat=stats[site]
            inv=cond['inv']=h['inv']
            cmp=cond['cmp']=h['val']
            actual=stat['msg'][var]||stat.get(var)
            verbose("McrStep","site=#{site},var=#{var},inv=#{inv},cmp=#{cmp},actual=#{actual}")
            cond['act']=actual
            cond['res']=match?(actual,cmp,cond['inv'])
          cond
        }
        res=conds.all?{|h| h['res']}
        self['conditions']=conds
        self['result']=(res ? t : f) if t || f
        res
      end

      def scan
        sites.inject({}){|hash,site|
          hash[site]=@cfg[:wat_list].site(site).ash.stat
          hash
        }
      end

      def refresh
        sites.each{|site|
          @cfg[:wat_list].site(site).ash.stat.refresh
        }
      end

      def sites
        @condition.map{|h| h['site']}.uniq
      end

      def match?(actual,cmp,inv)
        i=(/true|1/ === inv)
        if /[a-zA-Z]/ === cmp
          (/#{cmp}/ === actual) ^ i
        else
          (cmp == actual) ^ i
        end
      end
    end
  end
end
