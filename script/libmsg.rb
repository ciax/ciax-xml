#!/usr/bin/ruby

class UserError < RuntimeError; end
class SelectID < UserError; end
class SelectCMD < SelectID; end

class Msg
  class Ver
    Start_time=Time.now
    @@base=1
    def initialize(prefix='',color=2)
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
      return unless ENV['VER'] && ! ENV['VER'].empty?
      @ind=@@base
      @@base+=add
      @ind=@@base if add < 0
      [*yield].each{|str|
        msg=mkmsg(str)
        Kernel.warn msg if condition(msg)
      }
      self
    end

    # Private Method
    private
    def mkmsg(text)
      return unless text
      pass=sprintf("%5.4f",Time.now-Start_time)
      ts= STDERR.tty? ? '' : "[#{pass}]"
      ts+'  '*@ind+Msg.color("#{@prefix}:",@color)+text.inspect
    end

    def condition(msg) # VER= makes setenv "" to VER otherwise nil
      return true if /\*/ === ENV['VER']
      ENV['VER'].upcase.split(',').any?{|s|
        s.split(':').all?{|e|
          msg.upcase.include?(e)
        }
      }
    end
  end

  class List < Hash
    def initialize(title=nil)
      @title=Msg.color(title,2) if title
    end

    def add(hash)
      hash.each{|key,val|
        case val
        when String
          label=val
        when Hash,Xml
          label=val['label']
        end
        self[key]=Msg.color(" %-10s" % key,3)+": #{label}" if label
      }
      self
    end

    def sort! # For ver 1.9 or more
      hash={}
      keys.sort.each{|k|
        hash[k]=self[k]
      }
      replace(hash)
    end

    def to_s
      [$!.to_s,@title,*values].grep(/./).join("\n")
    end
  end

end

class << Msg
  # Class method
  def view_struct(data,title=nil,indent=0)
    return '' unless data
    str=''
    if title
      case title
      when Numeric
        title="[#{title}]"
      else
        title=title.inspect
      end
      str << "  " * indent + ("%-4s :\n" % title)
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
      if data.values.any?{|v| ! v.kind_of?(Comparable)} || data.size > 4
        data.each{|k,v|
          str << view_struct(v,k,indent)
        }
        return str
      end
    end
    str.chomp + " #{data.inspect}\n"
  end

  def warn(msg='warning') # Display only
    Kernel.warn color(msg,3)
    self
  end

  def alert(msg='alert') # Display only
    Kernel.warn $!.to_s+color(msg,1)
    self
  end

  def err(*msg) # Raise User error (Invalid User input)
    msg[0]=color(msg[0],1)
    raise UserError,$!.to_s+msg.join("\n")
  end

  def abort(msg='abort')
    Kernel.abort([color(msg,1),$!.to_s].join("\n"))
  end

  def exit(code=1)
    Kernel.warn($!.to_s)
    Kernel.exit(code)
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

  # 1=red,2=green,4=blue,8=bright
  def color(text,c=7)
    return '' if text == ''
    return text unless STDERR.tty?
    "\033[#{c>>3};3#{c&7}m#{text}\33[0m"
  end
end

