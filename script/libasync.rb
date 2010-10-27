#!/usr/bin/ruby
require "libclscmd"
require "timeout"
require "thread"

class Async < Array

  def initialize(queue,cdb,sdb,fi)
    @q=queue
    @cdb=cdb
    @sdb=sdb
    @fi=fi
    @errmsg=Array.new
    @timeout=10
    @interval=10
    @stat=[]
    @v=Verbose.new("ASYNC")
  end

  def set_async(e0)
    a=e0.attributes
    @timeout=a['timeout'] ? a['timeout'].to_i : @timeout
    @interval=a['interval'] ? a['interval'] : @interval
    e0.each_element{|e1| # //async/*
      case e1.name
      when 'until_any'
        @stat=[]
        e1.each_element{|e2| #stat
          key=@cdb.par.subst(e2.attributes['ref'])
          @stat << {:sp=>@sdb.acc_stat(key),:val=>e2.text}
        }
      else
        @var[e1.name]=_mk_array(e1) #session
      end
    }
  end

  def async
    self << Thread.new {
      begin
        timeout(@timeout){
          @stat.any?{|hash|
            @v.msg{"Exit if #{hash[:sp]} == #{hash[:val]}" }
            hash[:sp] == hash[:val]
          } && break
          _exec(@var['execution']) if @q.empty?
          sleep @interval
        }
        _exec(@var['completion'])
      rescue
        @errmsg << $!.to_s
      ensure
        @var['blocking']=[]
        @var['interrupt']=[]
      end
    }
  end

  def stop
    @q.replace(@var['interrupt'])
    @var['blocking']=[]
    @var['interrupt']=[]
  end

  private
  def _mk_array(e)
    ary=[]
    e.each_element{ |e1| #statement
      ary << @fi.call(@cdb.get_cmd(e1))
    }
    ary
  end

  def _exec(ary)
    ary.each {|s| @q.push(s) } if ary
  end
end
