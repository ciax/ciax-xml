#!/usr/bin/ruby
require 'libupd'
require 'libmcrprt'

module CIAX
  module Mcr
    # Element of Record
    class Step < Upd
      include PrtShare
      def initialize(db,dev_list)
        super()
        update db
        #[:stat_proc,:exec_proc,:submcr_proc,:query]
        @dev_list=type?(dev_list,App::List)
        @condition=delete('cond')
        @break=nil
      end

      # Conditional judgment section
      def timeout?
        itv=($opt['e'] || $opt['s'])? 0.1 : 0
        itv*=10 if $opt['m']
        show title
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
        show title
        upd
        'ok'
      end

      def skip?
        show title
        res=condition_ok?('skip','pass')
        upd
        res
      end

      def fail?
        show title
        res=! condition_ok?('pass','failed')
        upd
        res
      end

      # Interactive section
      def exec?
        show title
        res= !dryrun?
        self['result']= res ? 'exec' : 'skip'
        upd
        res
      end

      # Execution section
      def async?
        show title
        res=(/true|1/ === self['async'])
        self['result']= res ? 'forked' : 'entering'
        upd
        res
      end

      # Display section
      def to_v
        title+result
      end

      private
      def upd_core
        show result
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
          cmp=cond['cmp']=h['cmp']
          cri=cond['cri']=h['val']
          form=cond['form']=h['form']
          case form
          when 'class','msg'
            warning("No key value [#{var}] in Status[#{form}]") unless stat[form].key?(var)
            real=stat[form][var]
          when 'data'
            real=stat.get(var)
          else
            warning('No form specified')
          end
          verbose{"site=#{site},var=#{var},form=#{form},cmp=#{cmp},cri=#{cri},real=#{real}"}
          cond['real']=real
          cond['res']=match?(real,cri,cond['cmp'])
          cond
        }
        res=conds.all?{|h| h['res']}
        self['conditions']=conds
        self['result']=(res ? t : f) if t || f
        res
      end

      def scan
        sites.inject({}){|hash,site|
          verbose{"Scanning Status #{site}"}
          hash[site]=@dev_list.get(site).stat
          hash
        }
      end

      def refresh
        sites.each{|site|
          verbose{"Refresh Status #{site}"}
          @dev_list.get(site).stat.refresh
        }
      end

      def sites
        @condition.map{|h| h['site']}.uniq
      end

      def match?(real,cri,cmp)
        case cmp
        when 'equal'
          cri == real
        when 'not'
          cri != real
        when 'match'
          /#{cri}/ =~ real
        when 'unmatch'
          /#{cri}/ !~ real
        else
          false
        end
      end
    end
  end
end
