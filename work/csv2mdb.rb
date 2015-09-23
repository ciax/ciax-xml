#!/usr/bin/ruby
# IDB,CDB CSV(CIAX-v1) to MDB
#alias c2m
require 'json'
abort "Usage: csv2mdb [sites]" if ARGV.size < 1

def add_site(line,site)
  line.split('&').map{|s|
    [site,s]
  }
end

def spl(line,del)
  line.split(del).map{|s|
    s.split(':')
  }
end

mdb={}
index={}
ARGV.each{|site|
  proj='-'+(ENV['PROJ']||'moircs') if site == 'mcr'
  grp={}
  open(ENV['HOME']+"/config/idb_#{site}#{proj}.txt"){|f|
    f.readlines.each{|line|
      next if /^[a-zA-Z0-9]/ !~ line
      id,goal,check=line.chomp.split(',')
      case site
      when /mcr/
        con=grp[id]={}
        con['goal']=spl(goal,"&") if goal and !goal.empty?
        con['check']=spl(check,"&") if check and !check.empty?
      else
        con=grp["#{site}_#{id}"]={}
        con['goal']=add_site(goal,site) if goal and !goal.empty?
        con['check']=add_site(check,site) if check and !check.empty?
      end
    }
  }
  open(ENV['HOME']+"/config/cdb_#{site}#{proj}.txt"){|f|
    f.readlines.each{|line|
      next if /^[a-zA-Z0-9]/ !~ line
      id,label,inv,type,seq=line.chomp.split(',')
      next if type == 'cap'
      case site
      when /mcr/
        con=(grp[id]||={})
        con['label']=label
        con['seq']=spl(seq," ").map{|ary|
          id=ary.join('_')
          index.key?(id) ? ['mcr',id] : ary
        } if seq and !seq.empty?
      else
        con=(grp["#{site}_#{id}"]||={})
        con['label']=label
        con['exec']=[[site,id]]
        if seq
          pre,mid,post=seq.split('/')
          if mid
            rtry,cri,*upd=mid.split(':')
            wait=con['wait']={'retry'=> rtry}
            wait['until']=add_site(cri,site) if cri and !cri.empty?
            if post
              wait['post']=spl(post,'&')
            end
          end
        end
      end
    }
  }
  mdb["grp_#{site}"]=grp.select{|k,v|
    ['wait','seq','goal','check'].any?{|f| v.key?(f)}
  }
}
print JSON.dump mdb
