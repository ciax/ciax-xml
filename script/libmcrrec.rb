#!/usr/bin/ruby
require "libvar"
require "libstatus"
require "libcommand"
require "libmcrprt"

module Mcr
  class Record < Var
    attr_accessor :stat_proc,:exe_proc
    attr_reader :crnt,:base
    def initialize(item)
      @cobj=Msg.type?(item.index,Command)
      super('mcr')
      @base=Time.new.to_f
      self['id']=@base.to_i
      self['cmd']=item.cmd
      self['label']=item[:label]
      self['steps']=[]
      self['total']=0
      self[:exclude]='[esdfr]'
      @stat_proc=proc{|site| Status::Var.new}
      @exe_proc=proc{|site,cmd,depth|}
    end

    def macro(item,depth=1)
      Msg.type?(item,Command::Item).select.each{|e1|
        begin
          @crnt=Step.new(e1,self,depth)
          @crnt.extend(Prt) unless $opt['r']
          self['steps'] << @crnt
          case e1['type']
          when 'goal'
            @crnt.skip? && raise(Skip)
          when 'check'
            @crnt.fail? && raise(Interlock)
          when 'wait'
            @crnt.timeout? && raise(Interlock)
          when 'exec'
            @crnt.exec
          when 'mcr'
            puts @crnt if Msg.fg?
            macro(@cobj.setcmd(e1['cmd']),depth+1)
          end
        rescue Retry
          retry
        rescue Skip
          return
        ensure
          self['total']="%.3f" % (Time.now.to_f-@base)
        end
      }
      self
    end
  end

  class Step < ExHash
    def initialize(db,obj,depth=0)
      @obj=Msg.type?(obj,Record)
      @stat_proc=Msg.type?(obj.stat_proc,Proc)
      @exe_proc=Msg.type?(obj.exe_proc,Proc)
      self['time']="%.3f" % (Time.now.to_f-obj.base)
      self['depth']=depth
      update(Msg.type?(db,Hash))
      @condition=delete('stat')
    end

    def exec
      puts title if Msg.fg?
      if query_exec?
        @exeproc.call(self['site'],self['cmd'],self['depth'])
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
      puts result if Msg.fg?
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
      puts to_s if Msg.fg?
      query_quit?
    end

    def title ; self['label']||self['cmd']; end
    def result ; "\n"+to_s; end
    def action ; "\n"; end

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
      loop{
        case input(['Exec','Skip'],'[dfr]')
        when /^E/i
          if dryrun?
            self['action']='dryrun'
            return false
          else
            self['action']='exec'
            return true
          end
        when /^S/i
          self['action']='skip'
          return false
        end
      }
    end

    def query_quit?
      return true if $opt['n']
      loop{
        case input(['Done','Force','Retry'],'[es]')
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

    def input(cmds,exc)
      cmdstr='['+cmds.join('/')+']?'
      prompt=Msg.color(cmdstr,5)
      @obj[:exclude]=exc
      if Msg.fg?
        print Msg.indent(self['depth'].to_i+1)
        self[:query]=Readline.readline(prompt,true)
      else
        self[:query]=prompt
        sleep
      end
      @obj[:exclude]='[esdfr]'
      delete(:query)
    end
  end
end
