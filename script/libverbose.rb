#!/usr/bin/ruby

class UserError < RuntimeError; end
class SelectID < UserError; end

class Verbose
  Start_time=Time.now
  @@base=1
  def initialize(prefix='',color=7)
    @prefix=prefix.upcase
    @color=color
    @ind=1
    @list=[]
    msg{"Initialize Messaging"}
  end

  # Public Method
  def msg(add=0)
    # block takes array (shown by each line)
    # [val] -> taken from  xml
    # <val> -> taken from status
    return unless ENV['VER']
    @ind=@@base
    @@base+=add
    @ind=@@base if add < 0
    [*yield].each{|str|
      msg=mkmsg(str)
      Kernel.warn msg if condition(msg)
    }
    self
  end

  def warn(msg='warning') # Display only
    Kernel.warn color(msg,3)
    self
  end

  def alert(msg='alert') # Display only
    Kernel.warn $!.to_s+color(msg,1)
    self
  end

  def err(msg='error') # Raise User error (Invalid User input)
    raise UserError,$!.to_s+color(msg,1)
  end

  def abort(msg='abort')
    Kernel.abort color(msg,1)
  end

  def assert(exp)
    return exp if exp
    msg=defined?(yield) ? yield : "Assert exception"
    raise(color(msg,1))
  end

  def check(exp)
    return exp if exp
    msg=defined?(yield) ? yield : "Nil Data detected"
    Kernel.warn color(msg,5)
    exp
  end

  def add(list)
    case list
    when String
      @list << color(list,2)
    when Hash
      list.each{|key,val|
        case val
        when String
          label=val
        when Hash,XmlGn
          label=val['label']
        end
        @list << color(" %-10s" % key,3)+": #{label}" if label
      }
    end
    self
  end

  def to_s
    [$!.to_s,*@list].grep(/./).join("\n")
  end

  def list
    raise SelectID,to_s
  end

  # Private Method
  private
  # 1=red,2=green,4=blue,8=bright
  def color(text,c=@color)
    return '' if text == ''
    return text unless STDERR.tty?
    "\033[#{c>>3};3#{c&7}m#{text}\33[0m"
  end

  def mkmsg(text)
    return unless text
    pass=sprintf("%5.4f",Time.now-Start_time)
    ts= STDERR.tty? ? '' : "[#{pass}]"
    ts+'  '*@ind+color("#{@prefix}:",@color)+text.inspect
  end

  def condition(msg) # VER= makes setenv "" to VER otherwise nil
    if ENV['VER']
      ver=ENV['VER'].split(' ').map{|s| s.upcase}
      ver.any?{|s| msg.upcase.include?(s) }
    end
  end

  # Class method
  def self.view_struct(key,val,indent=0)
    return '' unless val
    str="  " * indent + ("%-4s :" % key.inspect)
    case val
    when Array
      unless val.all?{|v| v.kind_of?(Comparable)}
        str << "\n"
        val.each_with_index{|v,i|
          str << view_struct(i,v,indent+1)
        }
        return str
      end
    when Hash
      val=Hash[val]
      if val.values.any?{|v| ! v.kind_of?(Comparable)} || val.size > 4
        str << "\n"
        val.each{|k,v|
          str << view_struct(k,v,indent+1)
        }
        return str
      end
    end
    str << " #{val.inspect}\n"
  end
end
