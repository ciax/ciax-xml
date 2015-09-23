#!/usr/bin/ruby
# IDB,CDB CSV(CIAX-v1) to MDB
#alias c2m
require 'json'
abort "Usage: csv2mdb -m [sites]" if ARGV.size < 1
if ARGV[0] == '-m'
  getmcr=true
  ARGV.shift
end

def add_site(line,site)
  line.split('&').map{|s|
    [site,s]
  }
end

def spl_cond(line)
  line.split('&').map{|s|
    skip=nil
    site,cond=s.split(':').each{|e|
      if /^!/ =~ e
        skip='true'
        var=$'
      else
        var=e
      end
      var
    }
    abort "NO operator in #{s}" unless /[~!=^]/ =~ cond
    ope={'~'=>'match','!'=>'ne','='=>'eq','^'=>'unmatch'}[$&]
    [ope,site,$`,$',skip]
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
    con['goal']=add_site(goal,site) if goal and !goal.empty?
    con['check']=add_site(check,site) if check and !check.empty?
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
          wait['until']=add_site(cri,site)
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
    con['goal']=spl_cond(goal) if goal and !goal.empty?
    con['check']=spl_cond(check) if check and !check.empty?
  }
  get_csv("cdb_mcr#{proj}"){|id,label,inv,type,seq|
    next if type == 'cap'
    con=(grp[id]||={})
    con['label']=label.gsub(/&/,'and')
    con['seq']=spl_cmd(seq).map{|ary|
      id=ary.join('_')
      index.key?(id) ? ['mcr',id] : ary
    } if seq and !seq.empty?
  }
end
print JSON.dump mdb
