#!/usr/bin/ruby
require "libstatus"
require "libcommand"
require "libmcrprt"

module CIAX
  module Mcr
    Dryrun=1
    class Record < Datax
      attr_accessor :depth
      # Level [0] Step, [1] Record & Item, [2] Group, [3] Domain, [4] Command
      def initialize
        super('record',[],'steps')
        self['id']=self['time'].to_i.to_s
        extend PrtRecord unless $opt['r']
        @depth=0
        ext_file(self['id'])
      end

      def add_step(e1,shary)
        step=Step.new(e1,@depth,shary){save}
        step['time']=Msg.elps_sec(self['time'])
        @data << step
        step
      end

      def finish(str)
        self['result']=str
        self['total']=Msg.elps_sec(self['time'])
        save
      end
    end

    class Step < Hashx
      def initialize(db,depth,shary,&save_proc)
        update db
        self['depth']=depth
        #[:stat_proc,:exec_proc,:submcr_proc,:query,:show_proc]
        @shary=shary
        @save=save_proc
        @condition=delete('stat')
        @break=nil
        extend PrtStep unless $opt['r']
      end

      # Conditional judgment section
      def timeout?
        print title if Msg.fg?
        self['max']=self['retry']
        max = dryrun? ? Dryrun : self['max']
        res=max.to_i.times{|n| #gives number or nil(if break)
          self['retry']=n
          break if ok?
          refresh
          sleep 1
          yield
          @save.call
        }
        self['result']= res ? 'timeout' : 'pass'
        save
        res
      end

      def skip?
        print title if Msg.fg?
        res=ok?('skip','pass') && !dryrun?
        save
        res
      end

      def fail?
        print title if Msg.fg?
        res=! ok?('pass','failed')
        save
        res
      end

      # Interactive section
      def exec?
        print title if Msg.fg?
        res= !dryrun?
        self['result']= res ? 'exec' : 'skip'
        save
        res
      end

      # Execution section
      def async?
        print title if Msg.fg?
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
        @save.call
        print result if Msg.fg?
      end

      def dryrun?
        ! ['e','s','t'].any?{|i| $opt[i]} && self['action']='dryrun'
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
    end

    if __FILE__ == $0
      GetOpts.new('r')
      $opt.usage "(-r) < record_file" if STDIN.tty?
      puts Record.new.read
    end
  end
end

