#!/usr/bin/ruby
# XML Common Method
require 'librerange'
class ConvStr
  attr_reader :par
  attr_accessor :var

  def initialize(v)
    @v,@var,@par=v,{},[]
  end

  def repeat(e)
    a=e.attributes
    fmt=a['format'] || '%d'
    counter=a['counter'] || '_'
    counter.next! while @var[counter]
    @v.msg{"Repeat:Counter[\$#{counter}]"}
    @v.msg{"Repeat:Range[#{a['from']}]-[#{a['to']}]"}
    @v.msg{"Repeat:Format[#{fmt}]"}
    Range.new(a['from'],a['to']).each { |n|
      @var[counter]=fmt % n
      e.each_element { |d| yield d}
    }
    @var.delete(counter)
  end

  def set_par(par)
    @par=par
    par.each_with_index{|s,n| @var[(n+1).to_s]=s }
  end

  def sub_var(str)
    return str unless /\$/ === str
    @v.msg{"Substitute from [#{str}]"}
    h=@var.clone
    str=str.gsub(/\$([_`\w])/){ h[$1] }
    # Sub ${id} by hash[id]
    str=str.gsub(/\$\{([\w:]+)\}/) {
      $1.split(':').each {|i| h=h[i] };h }
    @v.msg{"Substitute to [#{str}]"}
    str
  end

end
