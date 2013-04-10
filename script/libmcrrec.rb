#!/usr/bin/ruby
require "libvar"
require "libstatus"
require "libmcrprt"

module Mcr
  class Record < Var
    attr_accessor :stat_proc,:exe_proc
    attr_reader :crnt,:base
    def initialize(cmd,label)
      @stat_proc=proc{|site| Status::Var.new}
      @exe_proc=proc{|site,cmd,depth|}
      super('mcr')
      @base=Time.new.to_f
      self['id']=@base.to_i
      self['cmd']=cmd
      self['label']=label
      self['steps']=[]
      self['total']=0
    end

    def nextstep(db,depth=0)
      @crnt=Step.new(db,self,depth)
      @crnt.extend(Prt) unless $opt['r']
      self['steps'] << @crnt
      case db['type']
      when 'goal'
        @crnt.skip? && raise(Skip)
      when 'check'
        @crnt.fail? && raise(Interlock)
      when 'wait'
        @crnt.timeout? && raise(Interlock)
      when 'exec'
        @crnt.exec(@exe_proc)
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
    def initialize(db,obj,depth=0)
      @obj=Msg.type?(obj,Record)
      @stat_proc=Msg.type?(obj.stat_proc,Proc)
      self['time']="%.3f" % (Time.now.to_f-obj.base)
      self['depth']=depth
      update(Msg.type?(db,Hash))
      @condition=delete('stat')
    end

    def exec(exeproc)
      if query_exec?
        exeproc.call(self['site'],self['cmd'],self['depth'])
        self['result']='done'
      else
        self['result']='skip'
      end
    end

    def timeout?
      #gives number or nil(if break)
      print title if Msg.fg?
      max=self['max']=self['retry']
      max = 3 if dryrun?
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
      query_quit?
    end

    def skip?
      return true if ok?('skip','pass')
      return if dryrun?
      true
    ensure
      puts to_s if Msg.fg?
    end

    def fail?
      return if ok?('pass','failed')
      print title if Msg.fg?
      query_quit?
    end

    def title ; self['label']||self['cmd']; end
    def result ; "\n"+to_s; end

    private
    def ok?(t=nil,f=nil)
      res=(flt=scan).empty?
      self['mismatch']=flt unless res
      self['result']=(res ? t : f) if t || f
      res
    end

    def scan
      stats=sites.inject({}){|hash,site|
        hash[site]=@stat_proc.call(site).load
        hash
      }
      @condition.map{|h|
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
      @condition.map{|h| h['site']}.uniq
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
      ! ['e','s','t'].any?{|i| $opt[i]}
    end

    def query_exec?
      return true if $opt['n']
      puts title if Msg.fg?
      loop{
        case input("[Exec/Skip/Quit]?")
        when /^[eE]/
          if dryrun?
            self['action']='dryrun'
            return false
          else
            self['action']='exec'
            return true
          end
        when /^[sS]/
          self['action']='skip'
          return false
        when /^[qQ]/
          self['action']='quit'
          raise(Quit)
        end
      }
    ensure
        puts result if Msg.fg?
    end

    def query_quit?
      return true if $opt['n']
      puts result if Msg.fg?
      loop{
        case input("[Quit/Force/Retry]?")
        when /^[qQ]/
          self['action']='exit'
          return true
        when /^[fF]/
          self['action']='forced'
          return false
        when /^[rR]/
          self['action']='retry'
          raise(Retry)
        end
      }
    end

    def input(str)
      if Msg.fg?
        str=Msg.indent(self['depth'].to_i+1)+Msg.color(str,5)
        self[:query]=Readline.readline(str,true)
      else
        self[:query]=str
        sleep
      end
      delete(:query)
    end
  end
end
