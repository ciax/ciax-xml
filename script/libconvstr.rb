#!/usr/bin/ruby
# XML Common Method
require 'librerange'
class ConvStr
  attr_accessor :par,:str,:var

  def initialize(v)
    @v,@var,@str,@par,@n=v,{},'',[],nil
  end

  def to_s
    @str
  end

  def repeat(e)
    a=e.attributes
    fmt=a['format'] || '%d'
    Range.new(a['from'],a['to']).each { |n|
      @n=fmt % n
      e.each_element { |d| yield d}
    }
    @n=nil
  end

  def subnum(str) # Sub $_ by num
    @str=str
    return self unless @n && @str
    @str=@str.gsub(/\$_/,@n)
    @v.msg("Substutited to [#{@str}]")
    self
  end

  def subpar(str=nil) # Sub $1 by pary[1]
    @str=str if str
    if /\$[\d]/ === @str
      @par.each_with_index{|s,n| @str=@str.gsub(/\$#{n+1}/,s)}
      @v.msg("Substutited to [#{@str}]")
    end
    self
  end

  def subvar(str=nil)
    @str=str if str
    return self unless /\$/ === @str
    h=@var.clone
    # Sub ${id} by hash[id]
    @str=@str.gsub(/\$\{([\w:]+)\}/) {
      $1.split(':').each {|i| h=h[i] }
      h
    }
    @v.msg{"Substitute to [#{@str}]"}
    self
  end

  def esc(str=nil) # convert escape char (i.e. "\n"..)
    @str=str if str
    @str=Kernel.eval('"'+@str+'"').to_s
    self
  end

  def eval(str=nil)
    @str=str if str
    @str=Kernel.eval(@str)
    self
  end

end
