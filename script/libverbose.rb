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
    # Description of values
    #   [val] -> taken from  xml (criteria)
    #   <val> -> taken from status (incoming)
    #   (val) -> calcurated from status
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
        when Hash,Xml
          label=val['label']
        end
        @list << color(" %-10s" % key,3)+": #{label}" if label
      }
    end
    self
  end

  def to_s
    @list.unshift($!.to_s) if $!
    @list.grep(/./).join("\n")
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
    case ENV['VER']
    when ''
      true
    else
      ENV['VER'].upcase.split(',').any?{|s|
        s.split(':').all?{|e|
          msg.upcase.include?(e)
        }
      }
    end
  end

  # Class method
  def self.view_struct(data,title=nil,indent=0)
    return '' unless data
    str=''
    if title
      str << "  " * indent + ("%-4s :\n" % title.inspect)
      indent+=1
    end
    case data
    when Array
      unless data.all?{|v| v.kind_of?(Comparable)}
        data.each_with_index{|v,i|
          str << view_struct(v,i,indent)
        }
        return str
      end
    when Hash
      data=Hash[data]
      if data.values.any?{|v| ! v.kind_of?(Comparable)} || data.size > 4
        data.each{|k,v|
          str << view_struct(v,k,indent)
        }
        return str
      end
    end
    str.chomp + " #{data.inspect}\n"
  end
end
