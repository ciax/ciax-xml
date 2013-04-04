#!/usr/bin/ruby
require "libvar"
require "libmcrprt"

module Mcr
  class Record < Var
    attr_accessor :stat_proc,:exe_proc,:err_proc
    attr_reader :crnt
    def initialize(cmd,label,opt={})
      @opt=Msg.type?(opt,Hash)
      @stat_proc=proc{{}}
      @exe_proc=proc{}
      @err_proc=proc{}
      super('mcr')
      @base=Time.new.to_f
      self['id']=@base.to_i
      self['cmd']=cmd.join(' ')
      self['label']=label
      self['total']=0
      self['steps']=[]
    end

    def newline(db,depth=0)
      @crnt=Step.new(db,@stat_proc,@base,depth,@opt)
      @crnt.extend(Prt) if @opt['v']
      self['steps'] << @crnt
      case db['type']
      when 'goal'
        res=@crnt.skip?
        puts @crnt if Msg.fg?
        res && (@err_proc.call(depth) || raise(Quit))
      when 'check'
        res=@crnt.fail?
        puts @crnt if Msg.fg?
        res && (@err_proc.call(depth) || raise(Interlock))
      when 'wait'
        print @crnt.title if Msg.fg?
        res=@crnt.timeout?
        puts @crnt.result if Msg.fg?
        res && (@err_proc.call(depth) || raise(Timeout))
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
    def initialize(db,stat_proc,timebase,depth=0,opt={})
      @stat_proc=Msg.type?(stat_proc,Proc)
      @opt=Msg.type?(opt,Hash)
      self['time']="%.3f" % (Time.now.to_f-timebase)
      self['depth']=depth
      self['result']='ok'
      update(db)
      @stat=delete('stat')
    end

    def timeout?
      #gives number or nil(if break)
      self['max']=self['retry']
      self['result']='broken'
      if self['retry'].to_i.times{|n|
          self['retry']=n
          break 1 if !['e','s','t'].any?{|i| @opt[i]}  && n > 3
          break if ok?
          sleep 1
          print '.' if Msg.fg?
        }
        self['result']='timeout'
      else
        self['result']='ok'
        false
      end
    end

    def skip?
      ok? && self['result']='skip'
    end

    def fail?
      !ok? && self['result']='failed'
    end

    def title ; end
    def result ; "\n"+to_s; end

    private
    def ok?
      sites.each{|site|
        @stat_proc.call(site).refresh
      }
      res=(flt=scan).empty?
      self['fault']=flt unless res
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
  end
end
