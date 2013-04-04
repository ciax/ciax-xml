#!/usr/bin/ruby
require "libvar"
require "libstatus"
require "libmcrprt"

module Mcr
  class Record < Var
    attr_accessor :stat_proc,:exe_proc
    attr_reader :crnt
    def initialize(cmd,label)
      @stat_proc=proc{|site| Status::Var.new}
      @exe_proc=proc{|site,cmd,depth|}
      super('mcr')
      @base=Time.new.to_f
      self['id']=@base.to_i
      self['cmd']=cmd.join(' ')
      self['label']=label
      self['total']=0
      self['steps']=[]
    end

    def nextstep(db,depth=0)
      @crnt=Step.new(db,@stat_proc,@base,depth)
      @crnt.extend(Prt) if $opt['v']
      self['steps'] << @crnt
      case db['type']
      when 'goal'
        @crnt.skip? && raise(Quit)
      when 'check'
        @crnt.fail? && raise(Interlock)
      when 'wait'
        @crnt.timeout? && raise(Interlock)
      when 'exec'
        puts @crnt if Msg.fg?
        @exe_proc.call(db['site'],db['cmd'],depth)
      when 'mcr'
        puts @crnt if Msg.fg?
        return db['cmd']
      end
      nil
    ensure
      self['total']="%.3f" % (Time.now.to_f-@base)
    end


  end

  class Step < ExHash
    def initialize(db,stat_proc,timebase,depth=0)
      @stat_proc=Msg.type?(stat_proc,Proc)
      self['time']="%.3f" % (Time.now.to_f-timebase)
      self['depth']=depth
      self['result']=''
      update(db)
      @stat=delete('stat')
    end

    def timeout?
      #gives number or nil(if break)
      print title if Msg.fg?
      self['max']=self['retry']
      res=self['retry'].to_i.times{|n|
        self['retry']=n
        break if dryrun?  && n > 3
        return if ok?('pass','broken')
        refresh
        sleep 1
        print '.' if Msg.fg?
      }
      self['result']='timeout'
      res
    ensure
      puts result if Msg.fg?
    end

    def skip?
      res=ok?('skip','pass')
      return if dryrun?
      res
    ensure
      puts to_s if Msg.fg?
    end

    def fail?
      res=!ok?('pass','failed')
      return if dryrun?
      res
    ensure
      puts to_s if Msg.fg?
    end

    def title ; end
    def result ; "\n"+to_s; end

    private
    def ok?(t=nil,f=nil)
      res=(flt=scan).empty?
      self['fault']=flt unless res
      self['result']=(res ? t : f) if t || f
      res
    end

    def scan
      stats=sites.inject({}){|hash,site|
        hash[site]=@stat_proc.call(site).load
        hash
      }
      @stat.map{|h|
        flt={}
        site=flt['site']=h['site']
        var=flt['var']=h['var']
        stat=stats[site]
        if flt['upd']=stat.update?
          inv=flt['inv']=h['inv']
          cmp=flt['cmp']=h['val']
          res=stat['msg'][var]||stat['val'][var]
          verbose{"site=#{site},var=#{var},inv=#{inv},cmp=#{cmp},res=#{res}"}
          next unless res
          flt['res']=res
          match?(res,cmp,flt['inv']) && flt || nil
        else
          flt
        end
      }.compact
    end

    def refresh
      sites.each{|site|
        @stat_proc.call(site).refresh
      }
    end

    def sites
      @stat.map{|h| h['site']}.uniq
    end

    def match?(res,cmp,inv)
      i=(/true|1/ === inv)
      if /[a-zA-Z]/ === cmp
        (/#{cmp}/ === res) ^ i
      else
        (cmp == res) ^ i
      end
    end

    def dryrun?
      if ! ['e','s','t'].any?{|i| $opt[i]}
        self['dryrun']=true
      end
    end
  end
end
