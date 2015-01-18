#!/usr/bin/ruby
require "libstatus"
require "libcommand"
require "libmcrprt"

module CIAX
  module Mcr
    class Record < Datax
      # Level [0] Step, [1] Record & Item, [2] Group, [3] Domain, [4] Command
      attr_reader :cfg
      def initialize(db={})
        super('record',[],'steps')
        self['id']=db['id'] # Project
        self['ver']=db['version'] # Version
        extend PrtRecord
      end

      def start(cfg)
        @cfg=type?(cfg,Config)
        self['sid']=self['time'].to_s # Session ID
        self['cid']=@cfg[:cid] # Command ID (cmd:par)
        self['label']=@cfg['label'] # Label for CID
        ext_file(self['sid'])
        self
      end

      def add_step(e1)
        Msg.type?(@cfg[:wat_list],Wat::List)
        step=Step.new(e1,@cfg)
        step.vmode.replace @vmode
        step.post_upd_procs << proc{post_upd}
        step['time']=Msg.elps_sec(self['time'])
        @data << step
        step
      ensure
        post_upd
      end

      def finish(str)
        self['result']=str
        self['total_time']=Msg.elps_sec(self['time'])
        self
      ensure
        post_upd
      end

      def ext_http(host,sid)
        @post_upd_procs << proc{
          @data.each{|v|
            v.extend PrtStep
          }
        }
        super
      end
    end

    class Step < Upd
      def initialize(db,cfg)
        super()
        update db
        self['depth']=db['depth']
        #[:stat_proc,:exec_proc,:submcr_proc,:query,:show_proc]
        @cfg=cfg
        @condition=delete('stat')
        @break=nil
        extend PrtStep
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
      def title ; self['label']||self['cmd']; end
      def result ; "\n"+to_s; end
      def body(msg); msg; end

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

    if __FILE__ == $0
      GetOpts.new('r')
      $opt.usage "(-r) < record_file" if STDIN.tty?
      puts Record.new.read
    end
  end
end
