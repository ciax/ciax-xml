#!/usr/bin/ruby
# IDB CSV(CIAX-v1) to XML
#alias m2x
require 'json'

def mktag(tag,attr)
  print '  '*@indent+'<'+tag
  attr.each{|k,v|
    print ' '+k+'="'+v+'"'
  }
end

def indent(tag,attr={},text=nil)
  mktag(tag,attr)
  if text
    puts ">#{text}</#{tag}>"
  else
    puts '/>'
  end
end

def enclose(tag,attr={})
  mktag(tag,attr)
  puts '>'
  @indent+=1
  yield
  @indent-=1
  puts '  '*@indent+"</#{tag}>"
end

def mkattr(vals,*tags)
  attr={}
  vals.each{|val|
    attr[tags.shift]=val
  }
  attr
end

def prt_cond(fld)
  fld.each{|ary|
    ope=ary.shift
    val=ary.shift
    attr=mkattr(ary,'site','var','skip')
    attr['form']='msg'
    indent(ope,attr,val)
  }
end

def prt_exe(ary)
  indent('exec',mkattr(ary,'site','name','skip'))
end

def prt_seq(seq)
  seq.each{|ary|
    if ary[0] != 'mcr'
      name="#{ary[0]}_#{ary[1]}"
      if !@mdb.key?(name)
        prt_exe(ary)
        next
      end
    else
      name=ary[1]
    end
    indent('mcr',{'name'=>name})
  }
end

abort "Usage: mdb2xml [mdb(json) file]" if STDIN.tty? && ARGV.size < 1

proj=ENV['PROJ']||'moircs'

@mdb=JSON.load(gets(nil))
@indent=0
puts '<?xml version="1.0" encoding="utf-8"?>'
enclose('mdb','xmlns'=>'http://ciax.sum.naoj.org/ciax-xml/mdb'){
  enclose('macro',{'id'=>proj,'version'=>'1','label'=>"#{proj.upcase} Macro",'port'=>'55555'}){
    @mdb.each{|grp,mem|
      enclose('group',{'id'=>grp}){
        mem.each{|id,db|
          attr={'id'=>id}
          attr['label']=db['label'] if db['label']
          enclose('item',attr){
            db.each{|key,ary|
              case key
              when 'goal'
                enclose("goal"){
                  prt_cond(ary)
                }
              when 'check'
                enclose("check"){
                  prt_cond(ary)
                }
              when 'exec'
                prt_exe(ary.first)
              when 'seq'
                prt_seq(ary)
              when 'wait'
                if ary['sleep']
                  indent("wait",{'sleep'=>ary['sleep']})
                else
                  enclose("wait",{'retry'=>ary['retry']}){
                    prt_cond(ary['until'])
                  }
                end
              when 'select'
                attr={'site'=>ary['site'],'var'=>ary['var'],'form'=>'msg'}
                enclose("select",attr){
                  ary['option'].each{|val,mcr|
                    enclose("option",{'val' => val}){
                      indent('mcr',{'name'=>mcr})
                    }
                  }
                }
              end
            }
          }
        }
      }
    }
  }
}
