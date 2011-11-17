#!/usr/bin/ruby
require 'libmsg'
class Repeat
  def initialize
    @v=Msg::Ver.new("repeat",5)
    @counter={}
    @rep=[]
  end

  def each(e0)
    e0.each{|e1|
      case e1.name
      when 'repeat'
        repeat(e1){
          each(e1){|e2|
            yield e2,self
          }
        }
      else
        yield e1,self
      end
    } if e0
  end

  def subst(str) # Sub $key => @counter[key]
    return str unless /\$([_a-z]+)/ === str
    res=str.gsub(/\$([_a-z]+)/){ @counter[$1] }
    res=eval(res).to_s unless /\$/ === res
    Msg.err("Empty String") if res == ''
    @v.msg{"Substitute [#{str}] to [#{res}]"}
    res
  end

  def format(str)
    return str unless str.include?('%')
    res = str % @counter.values
    @v.msg{"Format [#{str}] to [#{res}]"}
    res
  end

  private
  def repeat(e0)
    @rep.clear
    fmt=e0['format'] || '%d'
    c=e0['counter'] || '_'
    c.next! while @counter[c]
    @v.msg(1){"Counter[\$#{c}]/[#{e0['from']}-#{e0['to']}]/[#{fmt}]"}
    begin
      Range.new(e0['from'],e0['to']).each { |n|
        @v.msg(1){"Turn Number[#{n}]"}
        @counter[c]=fmt % n
        begin
          @rep.push yield
        ensure
          @v.msg(-1){"Turn End"}
        end
      }
      @counter.delete(c)
      self
    ensure
      @v.msg(-1){"End"}
    end
  end
end
