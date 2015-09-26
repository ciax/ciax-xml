#!/usr/bin/ruby
# IDB,CDB CSV(CIAX-v1) to MDB
#alias c2m
require 'json'
abort "Usage: csv2mdb -m [sites]" if ARGV.size < 1
if ARGV[0] == '-m'
  getmcr=true
  ARGV.shift
end

def get_site(elem)
  @skip=nil
  elem.split(':').map{|e|
    if /^!/ =~ e
      @skip='true'
      var=$'
    else
      var=e
    end
    var
  }
end

def spl_cond(line)
  line.split('&').map{|s|
    site,cond=yield s
    abort "NO operator in #{cond}" unless /[~!=^]/ =~ cond
    ope={'~'=>'match','!'=>'not','='=>'equal','^'=>'unmatch'}[$&]
    ary=[ope,$',site,$`]
    ary << @skip if @skip
    ary
  }
end

def spl_cmd(line,del=' ')
  line.split(del).map{|s|
    ary=s.split(':')
    if /^!/ =~ ary[0]
      ary[0]=$'
      ary << true
    end
    ary
  }
end

def get_csv(base)
  open(ENV['HOME']+"/config/#{base}.txt"){|f|
    f.readlines.each{|line|
      next if /^[a-zA-Z0-9]/ !~ line
      yield line.chomp.split(',')
    }
  }
end

mdb={}
index={}
# Convert device
ARGV.each{|site|
  grp={}
  get_csv("idb_#{site}"){|id,goal,check|
    con=grp["#{site}_#{id}"]={}
    con['goal']=spl_cond(goal){|cond| [site,cond]} if goal and !goal.empty?
    con['check']=spl_cond(check){|cond| [site,cond]} if check and !check.empty?
  }
  get_csv("cdb_#{site}"){|id,label,inv,type,cmd|
    next if type == 'cap'
    con=(grp["#{site}_#{id}"]||={})
    con['label']=label.gsub(/&/,'and')
    con['exec']=[[site,id]]
    if cmd
      pre,mid,post=cmd.split('/')
      if mid
        rtry,cri,*upd=mid.split(':')
        wait=con['wait']={}
        if cri
          wait['retry']=rtry
          wait['until']=spl_cond(cri){|cond| [site,cond]}
        else
          wait['sleep']=rtry
        end
        if post
          wait['post']=spl_cmd(post,'&')
        end
      end
    end
  }
  mdb["grp_#{site}"]=grp.select!{|k,v|
    ['wait','goal','check'].any?{|f| v.key?(f)}
  }
  index.update(grp)
}

# Convert mdb
if getmcr
  proj='-'+(ENV['PROJ']||'moircs')
  grp=mdb["grp_mcr"]={}
  get_csv("idb_mcr#{proj}"){|id,goal,check|
    con=grp[id]={}
    con['goal']=spl_cond(goal){|elem| get_site(elem)} if goal and !goal.empty?
    con['check']=spl_cond(check){|elem| get_site(elem)} if check and !check.empty?
  }
  select=[]
  get_csv("cdb_mcr#{proj}"){|id,label,inv,type,seq|
    next if type == 'cap'
    con=(grp[id]||={})
    con['label']=label.gsub(/&/,'and')
    con['seq']=spl_cmd(seq).map{|ary|
      id=ary.join('_')
      ary=index.key?(id) ? ['mcr',id] : ary
      if /%./ =~ ary[1]
        select << ary[1]
        ary[1]=ary[1].sub(/%(.)/,'X')
      end
      ary
    } if seq and !seq.empty?
  }
  unless select.empty?
    db={}
    get_csv("db_mcv#{proj}"){|id,var,list|
      db[id]={'var' => var,'list' => "#{list}".split(' ').map{|str| str.split('=')}}
    }
    grp=mdb['select']={}
    select.each{|str|
      id=str.sub(/%(.)/,'X')
      con=grp[id]={}
      dbi=db[$+]
      var=dbi['var'].split(':')
      con['label']='Select Macro'
      con['site']=var[0]
      con['var']=var[1]
      op=con['option']={}
      dbi['list'].each{|k,v|
        op[v]={'mcr' => str.sub(/%./,v),'val' => k}
      }
    }
  end
end
puts JSON.dump mdb
