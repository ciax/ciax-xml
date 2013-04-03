#!/usr/bin/ruby
require "libvar"
require "libapplist"

module Mcr
  class Record < Var
    attr_reader :crnt
    def initialize(aint,mcr,label,opt={})
      @aint=Msg.type?(aint,App::List)
      @opt=Msg.type?(opt,Hash)
      super('mcr')
      @base=Time.new.to_f
      @tc=Thread.current
      @tc[:stat]='ready'
      self[:id]=@base.to_i
      self[:mcr]=mcr
      self[:label]=label
      self[:total]=0
      self[:steps]=[]
    end

    def newline(db,depth=0)
      @crnt=Step.new(db,@aint,@base,depth,@opt)
      @tc[:stat]='run'
      self[:steps] << @crnt
      case db['type']
      when 'goal'
        if @crnt.skip?
          dryrun?(depth) || (return @tc[:stat])
        end
      when 'check'
        if @crnt.fail?
          dryrun?(depth) || (return @tc[:stat])
        end
      when 'wait'
        if @crnt.timeout?{print('.')}
          dryrun?(depth) || (return @tc[:stat])
        end
      when 'exec'
        yield @aint[db['site']],db['cmd']
      when 'mcr'
        return 'mcr'
      else
        nil
      end
    ensure
      self[:total]="%.3f" % (Time.now.to_f-@base)
    end

    private
    def dryrun?(depth)
      if @opt['t']
        Msg.hidden('Dryrun:Proceed',depth) if @opt['v']
        false
      else
        true
      end
    end
  end

  class Step < ExHash
    def initialize(db,aint,timebase,depth=0,opt={})
      @aint=Msg.type?(aint,App::List)
      @opt=Msg.type?(opt,Hash)
      @cs=Thread.current[:stat]
      self['time']="%.3f" % (Time.now.to_f-timebase)
      self['depth']=depth
      self['result']='ok'
      update(db)
      @stat=delete('stat')
    end

    def timeout?
      #gives number or nil(if break)
      self['max']=self['retry']
      @cs.replace('wait')
      if self['retry'].to_i.times{|n|
          self['retry']=n
          break 1 if  ! @opt['e'] && n > 3
          break if ok?
          sleep 1
          yield if @opt['v']
        }
        setres('timeout')
      end
    rescue Interrupt
      setres('broken')
    end

    def skip?
      ok? && self['result']='skip'
    end

    def fail?
      !ok? && self['result']='failed'
    end

    private
    def ok?
      sites.each{|site|
        getstat(site).refresh
      }
      res=(flt=scan).empty?
      self['result']=(res ? 'done' : 'failed')
      self['fault']=flt unless res
      res
    end

    def scan
      stats=sites.inject({}){|hash,site|
        hash[site]=getstat(site).load
        hash
      }
      @stat.map{|h|
        flt={}
        site=flt['site']=h['site']
        stat=stats[site]
        if flt['upd']=stat.update?
          inv=flt['inv']=h['inv']
          var=flt['var']=h['var']
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

    def getstat(site)
      @aint[site].stat
    end

    def setres(str)
      self['result']=str
      @cs.replace(str)
    end
  end
end
