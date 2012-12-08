#!/usr/bin/ruby
require "libapplist"
require "libmcrprt"

module Mcr
  class Record < Hash
    extend Msg::Ver
    def initialize(aint,opt={})
      @aint=Msg.type?(aint,App::List)
      @opt=Msg.type?(opt,Hash)
      @base=Time.new.to_f
      self[:id]=@base.to_i
      self[:stat]='(ready)'
      self[:total]=0
      self[:sequence]=[]
    end

    def newline(db,depth=0)
      @crnt={'depth' => depth}.update(db).extend(Prt)
      @crnt['elapsed']="%.3f" % (Time.now.to_f-@base)
      self[:sequence] << @crnt
      self
    end

    def fin
      self[:stat]='(done)' if self[:stat] == '(run)'
      self[:total]="%.3f" % (Time.now.to_f-@base)
      self
    end

    def prt(num=nil)
      if @opt['v']
        case num
        when 0
          print @crnt.title
        when 1
          print @crnt.result
        else
          print @crnt
        end
      end
    end

    def waiting
      self[:stat]="(wait)"
      #gives number or nil(if break)
      @crnt['max']=@crnt['retry']
      if @crnt['retry'].to_i.times{|n|
          @crnt['retry']=n
          break 1 if  @opt['t'] && n > 3
          break if ok?(1)
          sleep 1
          yield if @opt['v']
        }
        @crnt['timeout']=true
        self[:stat]='(timeout)'
      else
        self[:stat]='(run)'
      end
    end

    def ok?(refr=nil)
      res=(flt=scan).empty?
      @crnt['fault']=flt unless res
      @crnt.delete('stat') if res or !refr
      refresh if refr
      res
    end

    private
    def scan
      stats=load
      @crnt['stat'].map{|h|
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
        stats[site]=@aint[site].stat.load
      }
      stats
    end

    def refresh
      sites.each{|site|
        @aint[site].stat.refresh
      }
      @crnt
    end

    def sites
      @crnt['stat'].map{|h| h['site']}.uniq
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
