#!/usr/bin/ruby
require "libapplist"
require "libmcrprt"

module Mcr
  class Block < Hash
    attr_reader :crnt,:load,:refresh
    def initialize(load,refresh,opt={})
      @load=Msg.type?(load,Update)
      @refresh=Msg.type?(refresh,Update)
      @opt=Msg.type?(opt,Hash)
      @base=Time.new.to_f
      self[:id]=@base.to_i
      self[:stat]='(ready)'
      self[:total]=0
      self[:record]=[]
    end

    def newline(db,depth=0)
      @crnt=Record.new(db,@load,@refresh,depth,@opt)
      @crnt['elapsed']="%.3f" % (Time.now.to_f-@base)
      self[:record] << @crnt
      self
    end

    def fin
      self[:stat]='(done)' if self[:stat] == '(run)'
      self[:total]="%.3f" % (Time.now.to_f-@base)
      self
    end

    def waiting(&p)
      self[:stat]="(wait)"
      if @crnt.timeout?(&p)
        self[:stat]='(timeout)'
      else
        self[:stat]='(run)'
      end
    end
  end

  class Record < Hash
    extend Msg::Ver
    include Prt

    def initialize(db,load,refresh,depth=0,opt={})
      @load=Msg.type?(load,Update)
      @refresh=Msg.type?(refresh,Update)
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
      refresh if refr
      res
    end

    private
    def scan
      stats=load
      self['stat'].map{|h|
        flt={}
        site=flt['site']=h['site']
        stat=stats[site]
        if flt['upd']=stat.update?
          inv=flt['inv']=h['inv']
          var=flt['var']=h['var']
          cmp=flt['cmp']=h['val']
          res=stat['msg'][var]||stat['val'][var]
          Record.msg{"site=#{site},var=#{var},inv=#{inv},cmp=#{cmp},res=#{res}"}
          next unless res
          flt['res']=res
          match?(res,cmp,flt['inv']) && flt || nil
        else
          flt
        end
      }.compact
    end

    def load
      stats={}
      sites.each{|site|
        stats[site]=@load.exe(site)
      }
      stats
    end

    def refresh
      sites.each{|site|
        @refresh.exe(site)
      }
      self
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
  end
end
