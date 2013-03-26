#!/usr/bin/ruby
require "libvar"
require "libapplist"
require "libmcrprt"

module Mcr
  class Record < Var
    attr_reader :crnt
    def initialize(aint,opt={})
      @aint=Msg.type?(aint,App::List)
      @opt=Msg.type?(opt,Hash)
      super('mcr')
      @base=Time.new.to_f
      self[:id]=@base.to_i
      self[:stat]='ready'
      self[:total]=0
      self[:steps]=[]
    end

    def newline(db,depth=0)
      @crnt=Step.new(db,@aint,depth,@opt)
      @crnt['elapsed']="%.3f" % (Time.now.to_f-@base)
      self[:steps] << @crnt
      case db['type']
      when 'goal'
        if @crnt.ok?
          self[:stat]='done'
          live?(depth) && raise(Quit)
        end
        @crnt.prt
      when 'check'
        unless @crnt.ok?
          self[:stat]='fail'
          live?(depth) && raise(Interlock)
        end
        @crnt.prt
      when 'wait'
        @crnt.prt(0)
        self[:stat]="wait"
        if @crnt.timeout?{print('.')}
          self[:stat]='timeout'
        else
          self[:stat]='run'
        end
        @crnt.prt(1)
      else
        nil
      end
    end

    def fin(stat=nil)
      self[:stat]=stat if stat
      self[:total]="%.3f" % (Time.now.to_f-@base)
      self
    end

    private
    def live?(depth)
      if @opt['t']
        Msg.hidden('Dryrun:Proceed',depth) if @opt['v']
        false
      else
        true
      end
    end
  end

  class Step < ExHash
    include Prt
    def initialize(db,aint,depth=0,opt={})
      @aint=Msg.type?(aint,App::List)
      @opt=Msg.type?(opt,Hash)
      self['depth']=depth
      update(db)
    end

    def prt(num=nil)
      if @opt['v']
        case num
        when 0
          print title
        when 1
          print result
        else
          print self
        end
      end
    end

    def timeout?
      #gives number or nil(if break)
      self['max']=self['retry']
      if self['retry'].to_i.times{|n|
          self['retry']=n
          break 1 if  @opt['t'] && n > 3
          break if ok?(1)
          sleep 1
          yield if @opt['v']
        }
        self['timeout']=true
      end
    end

    def ok?(refr=nil)
      res=(flt=scan).empty?
      self['fault']=flt unless res
      delete('stat') if res or !refr #self.delete
      sites.each{|site|
        getstat(site).refresh
      } if refr
      res
    end

    private
    def scan
      stats=sites.inject({}){|hash,site|
        hash[site]=getstat(site).load
        hash
      }
      self['stat'].map{|h|
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
      self['stat'].map{|h| h['site']}.uniq
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
  end
end
