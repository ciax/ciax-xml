#!/usr/bin/ruby
# XML Common Method
require 'librerange'
class ConvStr
  attr_reader :par,:first # for shift
  attr_accessor :var

  def initialize(v)
    @v,@var,@par,@first=v,{},[]
  end

  def repeat(e)
    a=e.attributes
    fmt=a['format'] || '%d'
    counter=a['counter'] || '_'
    counter.next! while @var[counter]
    @v.msg{"Repeat:Counter[\$#{counter}]"}
    @v.msg{"Repeat:Range[#{a['from']}]-[#{a['to']}]"}
    @v.msg{"Repeat:Format[#{fmt}]"}
    @first=true
    Range.new(a['from'],a['to']).each { |n|
      @var[counter]=fmt % n
      e.each_element { |d| yield d}
      @first=nil
    }
    @var.delete(counter)
  end

  def par=(par)
    @par=par
    par.each_with_index{|s,n| @var[(n+1).to_s]=s }
  end

  def sub_var(str)
    return str unless /\$/ === str
    @v.msg{"Substitute from [#{str}]"}
    h=@var.clone
    str=str.gsub(/\$([_`\w])/){ h[$1] }
    # Sub ${key1:key2:idx} => hash[key1][key2][idx]
    str=str.gsub(/\$\{(.+)\}/) {
      $1.split(':').each {|i|
        @v.msg{"Var:Type[#{h.class}] Name[#{i}]"}
        i=eval(i) if Array === h
        h=h[i]
      }
      [*h].join(',')
    }
    return if str == ''
    @v.msg{"Substitute to [#{str}]"}
    str
  end

end
