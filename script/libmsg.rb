#!/usr/bin/ruby
VarDir="#{ENV['HOME']}/.var"

class UserError < RuntimeError; end
class SelectID < UserError; end
class SelectCMD < SelectID; end

module Msg
  class Ver
    Start_time=Time.now
    @@base=1
    def initialize(prefix='',color=2)
      if prefix.instance_of?(String)
        @prefix=prefix.upcase
      else
        @prefix=prefix.class.name
      end
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

    # VER= makes setenv "" to VER otherwise nil
    def condition(msg)
      return true if /\*/ === ENV['VER']
      ENV['VER'].upcase.split(',').any?{|s|
        s.split(':').all?{|e|
          msg.upcase.include?(e)
        }
      }
    end
  end

  # Structure /CommandID/Msg w/@title,@col
  class CmdList < Hash
    def initialize(title=nil,col=nil,color=6)
      @title='==== '+Msg.color(title,color)+' ====' if title
      @col=col||1
    end

    # For ver 1.9 or more
    def sort!
      hash={}
      keys.sort.each{|k|
        hash[k]=self[k]
      }
      replace(hash)
    end

    def to_s
      all=[]
      unless empty?
        all << @title
        keys.each_slice(@col){|a|
          l=a.map{|key|
            Msg.item(key,self[key]) if self[key]
          }.compact
          all << l.join("\t") unless l.empty?
        }
      end
      all.compact.join("\n")
    end

    def error
      raise SelectCMD,to_s
    end
  end

  # Structure /GroupID/List
  class GroupList < Hash
    def initialize(cdb={})
      @group={}
      if cdb.key?(:group)
        cdb[:group].each{|key,ary|
          hash={}
          (cdb.key?(:alias) ? ary.map{|k|
             cdb[:alias].key(k)
           }.compact : ary).each{|k|
            hash[k]=cdb[:label][k]
          }
          col=(cdb[:column]||{})[key] || 1
          cap=(cdb[:caption]||{})[key]||"Command List"
          @group[key]=CmdList.new(cap,col.to_i,2).update(hash)
          update(hash)
        }
      elsif cdb.key?(:label)
        @group['cmd']=CmdList.new("Command List",1,2).update(cdb[:label])
        update(cdb[:label])
      end
    end

    def add_group(key,title,hash={},col=1,color=6)
      @group[key]=CmdList.new(title,col,color)
      add_items(key,hash)
    end

    def add_items(key,hash)
      @group[key].update(hash)
      update(hash)
    end

    # search msg of each command
    def item(id)
      return Msg.item(id,self[id]) if key?(id)
      nil
    end

    def to_s
      ([$!]+@group.values).map{|v| v.to_s}.grep(/./).join("\n")
    end

    def error(str=nil)
      str= str ? str+"\n" : ''
      raise SelectCMD,str+to_s
    end
  end

  ### Class method ###
  module_function
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
    raise UserError,msg.join("\n"),caller(1)
  end

  def abort(msg='abort')
    Kernel.abort([color(msg,1),$!.to_s].join("\n"))
  end

  def usage(str,*opt)
    Kernel.warn("Usage: #{$0.split('/').last} #{str}")
    opt.each{|s|
      Kernel.warn(" "*6+s)
    }
    exit
  end

  def exit(code=1)
    Kernel.warn($!.to_s) if $!
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

  def item(key,val)
    Msg.color("  %-10s" % key,3)+": #{val}"
  end

  def view_struct(data,title=nil,indent=0)
    str=''
    col=4
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
      elsif  data.size > col
        str << "  "* indent + "["
        line=[]
        vary.each_slice(col){|a|
          line << a.map{|v| v.inspect}.join(",")
        }
        str << line.join(",\n "+"  " * indent)+"]\n"
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
