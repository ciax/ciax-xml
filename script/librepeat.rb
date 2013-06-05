#!/usr/bin/ruby
require 'libmsg'
class Repeat
  include Msg::Ver
  def initialize
    @ver_color=5
    @counter={}
    @format={}
    @rep=[]
  end

  def each(e0)
    e0.each{|e1|
      case e1.name
      when /repeat.*/
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
    return str unless /\$([_a-z])/ === str
    res=str.gsub(/\$([_a-z])/){ @counter[$1] }
    res=res.split(':').map{|i| /\$/ =~ i ? i : eval(i)}.join(':')
    Msg.cfg_err("Empty String") if res == ''
    verbose{["Repeat","Substitute [#{str}] to [#{res}]"]}
    res
  end

  def format(str)
    return str unless /\$([_a-z])/ === str
    res=str.gsub(/\$([_a-z])/){ @format[$1] % @counter[$1] }
    verbose{["Repeat","Format [#{str}] to [#{res}]"]}
    res
  end

  private
  def repeat(e0)
    @rep.clear
    c=e0['counter'] || '_'
    Msg.abort("Repeat:Counter Duplicate") if @counter.key?(c)
    fmt=@format[c]=e0['format'] || '%d'
    verbose(1){["Repeat","Counter[\$#{c}]/[#{e0['from']}-#{e0['to']}]/[#{fmt}]"]}
    begin
      Range.new(e0['from'],e0['to']).each { |n|
        verbose(1){["Repeat","Turn Number[#{n}]"]}
        @counter[c]=n
        begin
          @rep.push yield
        ensure
          verbose(-1){["Repeat","Turn End"]}
        end
      }
      @counter.delete(c)
      self
    ensure
      verbose(-1){["Repeat","End"]}
    end
  end
end
