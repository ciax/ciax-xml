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

      def title
        case self['type']
        when 'mesg'
          msg=head('Mesg',5)
        when 'goal'
          msg=head('Done?',6)
        when 'check'
          msg=head('Check',6)
        when 'wait'
          msg=head('Waiting',6)
        when 'mcr'
          msg=head("MACRO",3)
          msg << "(async)" if self['async']
        when 'exec'
          msg=head("EXEC",13)
        end
        msg
      end

      def result
        mary=['']
        mary[0] << "(#{self['retry']}/#{self['max']})" if self['max']
        if res=self['result']
          title=res.capitalize
          color=(/failed|timeout/ === res) ? 1 : 2
          mary[0] << ' -> '+Msg.color(title,color)
          if c=self['conditions']
            c.each{|h|
              if h['res']
                mary << body("#{h['site']}:#{h['var']}",3)+" is #{h['cmp']}"
              else
                mary << body("#{h['site']}:#{h['var']}",3)+" is not #{h['cmp']}"
              end
            }
          end
        end
        mary << body(self['action'].capitalize,8) if key?('action')
        mary << rindent(1)+Msg.optlist(self['option']) if key?('option')
        mary.join("\n")+"\n"
      end

      def setopt(ary)
        self['option']=ary
        upd
        self
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
          hash[site]=@cfg[:wat_list].get(site).stat
          hash
        }
      end

      def refresh
        sites.each{|site|
          @cfg[:wat_list].get(site).stat.refresh
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
