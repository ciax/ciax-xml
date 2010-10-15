#!/usr/bin/ruby
# XML Common Method
require 'librerange'
class ConvStr
  attr_reader :par,:first # for shift
  attr_accessor :stat

  def initialize(v)
    @v,@var,@par,@stat,@first=v,{},[],{}
  end

  def repeat(e)
    a=e.attributes
    fmt=a['format'] || '%d'
    counter=a['counter'] || '_'
    counter.next! while @var[counter]
    @v.msg(1){"Repeat:Counter[\$#{counter}]/Range[#{a['from']}-#{a['to']}]/Format[#{fmt}]"}
    begin
      @first=true
      Range.new(a['from'],a['to']).each { |n|
        @var[counter]=fmt % n
        e.each_element { |d| yield d}
        @first=nil
      }
      @var.delete(counter)
    ensure
      @v.msg(-1){"Repeat:Close"}
    end
  end

  def par=(par)
    @par=par
    par.each_with_index{|s,n| @var[(n+1).to_s]=s }
  end

  def sub_var(str)
    return str unless /\$/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      # Sub $key => @var[key]
      str=str.gsub(/\$([\w]+)/){ @var[$1] }
      # Sub ${key1:key2:idx} => hash[key1][key2][idx]
      # output csv if array
      str=str.gsub(/\$\{(.+)\}/) {
        [*acc_array($1,@stat)].join(',')
      }
      raise if str == ''
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end

  def acc_stat(key)
    acc_array(key,@stat)
  end

  def acc_array(key,h)
    return h unless key
    key.split(':').each {|i|
      @v.msg{"Var:Type[#{h.class}] Name[#{i}]"}
      i=eval(i) if Array === h
      h=h[i]||raise("No such Value [#{i}]")
    }
    h
  end
end
