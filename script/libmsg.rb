#!/usr/bin/ruby
VarDir="#{ENV['HOME']}/.var"

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
      msg{"Initialize Messaging"}
    end

    # Public Method
    def msg(add=0)
      # block takes array (shown by each line)
      # Description of values
      #   [val] -> taken from  xml (criteria)
      #   <val> -> taken from status (incoming)
      #   (val) -> calcurated from status
      return if ENV['VER'].to_s.empty?
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
    def initialize(title=nil,col=1)
      @title='==== '+Msg.color(title,2)+' ====' if title
      @col=col
    end

    def add(hash)
      hash.each{|key,val|
        case val
        when String
          label=val
        when Hash,Xml
          label=val['label']
        end
        self[key]=Msg.color("  %-10s" % key,3)+": #{label}" if label
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
      all=[$!.to_s,@title].grep(/./)
      values.each_slice(@col){|a|
        all << a.join("\t")
      }
      all.join("\n")
    end

    def error(str=nil)
      str= str ? str+"\n" : ''
      raise SelectCMD,str+to_s
    end
  end

  class Lists < Array
    def initialize(cdb)
      if cdb.key?(:group)
        cdb[:group].each{|key,ary|
          hash={}
          ary.reject{|k| /true|1/ === (cdb[:hidden]||{})[k] }.each{|k|
            hash[k]=cdb[:label][k]
          }
          col=(cdb.key?(:column) && cdb[:column][key]) || 1
          push List.new(cdb[:label][key]||"Command List",col.to_i).add(hash)
        }
      else
        push List.new("Command List").add(cdb[:label])
      end
    end

    def to_s
      join("\n")
    end

    def error(str=nil)
      str= str ? str+"\n" : ''
      raise SelectCMD,str+to_s
    end
  end
end

# Class method
class << Msg
  def now
    "%.3f" % Time.now.to_f
  end

  def msg(msg='message') # Display only
    Kernel.warn color(msg,2)
  end

  def warn(msg='warning') # Display only
    Kernel.warn color(msg,3)
  end

  def alert(msg='alert') # Display only
    Kernel.warn color(msg,1)
  end

  def err(*msg) # Raise User error (Invalid User input)
    msg[0]=color(msg[0],1)
    raise UserError,msg.join("\n")
  end

  def abort(msg='abort')
    Kernel.abort([color(msg,1),$!.to_s].join("\n"))
  end

  def exit(code=1)
    Kernel.warn($!.to_s)
    Kernel.exit(code)
  end

  def type?(name,mod,nul=false)
    return name if (nul && name.nil?) || name.is_a?(mod)
    raise "Parameter type error <#{name.class}> for (#{mod.to_s})"
  end

  # 1=red,2=green,4=blue,8=bright
  def color(text,c=7)
    return '' if text == ''
    return text unless STDERR.tty?
    "\033[#{c>>3};3#{c&7}m#{text}\33[0m"
  end

  def view_struct(data,title=nil,indent=0)
    str=''
    if title
      case title
      when Numeric
        title="[#{title}]"
      else
        title=title.inspect
      end
      str << "  " * indent + color("%-6s" % title,5)+" :\n"
      indent+=1
    end
    case data
    when Array
      vary=data
      idx=data.size.times
      if vary.any?{|v| v.kind_of?(Enumerable)}
        idx.each{|i|
          str << view_struct(data[i],i,indent)
        }
        return str
      elsif  data.size > 11
        vary.each_slice(11){|a|
          str << "  " * indent + "#{a.inspect}\n"
        }
        return str
      end
    when Hash
      vary=data.values
      idx=data.keys
      if vary.any?{|v| v.kind_of?(Enumerable)}
        idx.each{|i|
          str << view_struct(data[i],i,indent)
        }
        return str
      elsif data.size > 2
        idx.each_slice(title ? 2 : 1){|a|
          line=a.map{|k|
            color("%-8s" % k.inspect,3)+(": %-10s" % data[k].inspect)
          }.join("\t")
          str << "  " * indent + line + "\n"
        }
        return str
      end
    end
    str.chomp + " #{data.inspect}\n"
  end
end
