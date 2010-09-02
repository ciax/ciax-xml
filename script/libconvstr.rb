#!/usr/bin/ruby
# XML Common Method
require 'librerange'
class ConvStr
  attr_reader :par
  attr_accessor :str,:var

  def initialize(v)
    @v,@var=v,{}
  end

  def repeat(e)
    a=e.attributes
    fmt=a['format'] || '%d'
    counter=a['counter'] || '_'
    @v.msg{"Repeat Counter [\$#{counter}]"}
    Range.new(a['from'],a['to']).each { |n|
      @var[counter]=fmt % n
      e.each_element { |d| yield d}
    }
    @var.delete(counter)
  end

  def set_par(par)
    par.each_with_index{|s,n| @var[(n+1).to_s]=s }
  end

  def sub_var(str)
    return str unless /\$/ === str
    @v.msg{"Substitute from [#{str}]"}
    h=@var.clone
    str=str.gsub(/\$([_\d])/){ h[$1] }
    # Sub ${id} by hash[id]
    str=str.gsub(/\$\{([\w:]+)\}/) {
      $1.split(':').each {|i| h=h[i] };h }
    @v.msg{"Substitute to [#{str}]"}
    str
  end

end
