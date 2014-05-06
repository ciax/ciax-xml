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
        extend PrtRecord unless $opt['r']
        self['id']=db['id'] # Project
        self['ver']=db['version'] # Version
        self['sid']=self['time'].to_s # Session ID
      end

      def start(cfg)
        ext_file
        @cfg=type?(cfg,Config)
        self['cid']=@cfg[:cid] # Command ID (cmd:par)
        self['label']=@cfg['label'] # Label for CID
        self
      end

      def add_step(e1)
        Msg.type?(@cfg[:app],App::List)
        step=Step.new(e1,@cfg){save(self['sid'])}
        step['time']=Msg.elps_sec(self['time'])
        @data << step
        step
      end

      def finish(str)
        self['result']=str
        self['total']=Msg.elps_sec(self['time'])
        save(self['sid'])
        self
      end
    end

    class Step < Hashx
      def initialize(db,cfg,&save_procs)
        update db
        self['depth']=db['depth']
        #[:stat_proc,:exec_proc,:submcr_proc,:query,:show_proc]
        @cfg=cfg
        @save_procs=save_procs
        @condition=delete('stat')
        @break=nil
        extend PrtStep unless $opt['r']
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
          @save_procs.call
        }
        self['result']= res ? 'timeout' : 'pass'
        save
        res
      end

      def ok?
        show title
        res=self['result']='ok'
        save
        res
      end

      def skip?
        show title
        res=condition_ok?('skip','pass')
        save
        res
      end

      def fail?
        show title
        res=! condition_ok?('pass','failed')
        save
        res
      end

      # Interactive section
      def exec?
        show title
        res= !dryrun?
        self['result']= res ? 'exec' : 'skip'
        save
        res
      end

      # Execution section
      def async?
        show title
        res=(/true|1/ === self['async'])
        self['result']= res ? 'forked' : 'entering'
        save
        res
      end

      # Display section
      def title ; self['label']||self['cmd']; end
      def result ; "\n"+to_s; end
      def body(msg); msg; end

      private
      def save
        @save_procs.call
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
            actual=stat['msg'][var]||stat.data[var]
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
          hash[site]=@cfg[:app][site].stat
          hash
        }
      end

      def refresh
        sites.each{|site|
          @cfg[:app][site].stat.refresh
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

