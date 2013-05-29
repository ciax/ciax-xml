#!/usr/bin/ruby
require "libvar"
require "libstatus"
require "libcommand"
require "libmcrprt"

module Mcr
  class Record < Var
    attr_accessor :stat_proc
    attr_reader :crnt
    def initialize(obj)
      super('mcr')
      @obj=Msg.type?(obj,Sv)
      obj[:base]=Time.new.to_f
      self['id']=@obj[:base].to_i
      self['cmd']=obj.mobj.current.cmd
      self['label']=obj.mobj.current[:label]
      self['steps']=[]
      self['total']=0
    end

    def add_step(db,depth,&p)
      @crnt=Step.new(db,@obj,depth,p)
      @crnt.extend(Prt) unless $opt['r']
      self['steps'] << @crnt
      @crnt
    end

    def fin
      self['total']=Msg.elps_sec(@obj[:base])
    end
  end

  class Step < ExHash
    def initialize(db,obj,depth=0,p)
      obj=Msg.type?(obj,Sv)
      @stat_proc=Msg.type?(p,Proc)
      self['time']=Msg.elps_sec(obj[:base])
      self['depth']=depth
      update(Msg.type?(db,Hash))
      @condition=delete('stat')
      @query=Query.new(self,obj)
      @dryrun=! ['e','s','t'].any?{|i| $opt[i]}
    end

    def exec
      puts title if Msg.fg?
      if @query.exec?(@dryrun)
        yield(self['site'],self['cmd'],self['depth'])
        self['result']='done'
      else
        self['result']='skip'
      end
      puts action if Msg.fg?
    end

    def timeout?
      #gives number or nil(if break)
      print title if Msg.fg?
      max=self['max']=self['retry']
      if @dryrun
        max = 3
        self['action']='dryrun'
      end
      max.to_i.times{|n|
        self['retry']=n
        if ok?('pass','wait')
          puts result if Msg.fg?
          return
        end
        refresh
        sleep 1
        print '.' if Msg.fg?
      }
      self['result']='timeout'
      puts result if Msg.fg?
      @query.done?
    end

    def skip?
      return unless ok?('skip','pass')
      return true unless @dryrun
      self['action']='dryrun'
      false
    ensure
      puts to_s if Msg.fg?
    end

    def fail?
      return if ok?('pass','failed')
      puts to_s if Msg.fg?
      @query.done?
    end

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
        hash[site]=@stat_proc.call(site).load
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
          act=stat['msg'][var]||stat['val'][var]
          verbose{"site=#{site},var=#{var},inv=#{inv},cmp=#{cmp},act=#{act}"}
          next unless act
          cond['act']=act
          cond['res']=match?(act,cmp,cond['inv'])
        end
        cond
      }
    end

    def refresh
      sites.each{|site|
        @stat_proc.call(site).refresh
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

  class Query
    def initialize(step,sh)
      @step=Msg.type?(step,Step)
      @sh=Msg.type?(sh,Sv)
    end

    def exec?(dryrun=nil)
      return true if $opt['n']
      loop{
        case query(['Exec','Skip'])
        when /^E/i
          if dryrun
            @step['action']='dryrun'
            return false
          else
            @step['action']='exec'
            return true
          end
        when /^S/i
          @step['action']='skip'
          return false
        end
      }
    end

    def done?
      return true if $opt['n']
      loop{
        case query(['Done','Force','Retry'])
        when /^D/i
          @step['action']='done'
          return true
        when /^F/i
          @step['action']='forced'
          return false
        when /^R/i
          @step['action']='retry'
          raise(Retry)
        end
      }
    end

    private
    def query(cmds)
      inc=cmds.map{|s| s[0].downcase}
      @sh.intgrp.valid_keys.replace(inc)
      @sh['stat']='query'
      if Msg.fg?
        prompt=Msg.color('['+cmds.join('/')+']?',5)
        print Msg.indent(@step['depth'].to_i+1)
        res=Readline.readline(prompt,true)
      else
        @step['option']=cmds
        sleep
        @step.delete('option')
        res=Thread.current[:query]
      end
      @sh['stat']='run'
      @sh.intgrp.valid_keys.clear
      res
    end
  end
end
