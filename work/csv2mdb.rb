#!/usr/bin/ruby
# IDB,CDB CSV(CIAX-v1) to MDB
#alias c2m
require 'optparse'
require 'json'
abort "Usage: csv2mdb -m(proj) [sites]\n"\
      "  mcr is taken by -m\n"\
      '  sites for specific macro for devices' if ARGV.size < 1
opt = ARGV.getopts('m:')
@ope = { '~' => 'match', '!' => 'not', '=' => 'equal', '^' => 'unmatch' }
@unit=nil

def get_site(elem)
  @skip = nil
  elem.split(':').map do|e|
    if /^!/ =~ e
      @skip = 'true'
      var = $'
    else
      var = e
    end
    var
  end
end

def mk_cond(site, cond)
  case cond
  when /[~!=^]+/
    cri = $'.delete('/') # for '/S'
    ope = @ope[$&[0]] # for '=='
    ary = [ope, cri, site, $`]
    ary << @skip if @skip
    ary
  when '*', '', nil
    nil
  else
    abort "IDB: NO operator in #{cond}"
  end
end

def spl_cond(line)
  line.split('&').map do|s|
    site, cond = yield s
    mk_cond(site, cond)
  end.compact
end

def spl_cmd(line, del = ' ')
  line.split(del).map do|s|
    ary = s.split(':')
    if /^!/ =~ ary[0]
      ary[0] = $'
      ary << true
    end
    ary
  end
end

def get_csv(base)
  open(ENV['HOME'] + "/config/#{base}.txt") do|f|
    f.readlines.each do|line|
      @unit=nil if line.empty?
      next if /^[a-zA-Z0-9]/ !~ line
      yield line.chomp.split(',')
    end
  end
end

mdb = {}
cfgs = {}
index = {}
# Convert device
ARGV.each do|site|
  grp = {}
  cfga = cfgs[site] = []
  get_csv("idb_#{site}") do|id, gl, ck|
    con = grp["#{site}_#{id}"] = {}
    con['goal'] = spl_cond(gl) { |cond| [site, cond] } if gl && !gl.empty?
    con['check'] = spl_cond(ck) { |cond| [site, cond] } if ck && !ck.empty?
  end
  get_csv("cdb_#{site}") do|id, label, _inv, type, cmd|
    if type == 'cap'
      @unit = id
      next
    end
    con = (grp["#{site}_#{id}"] ||= {})
    con['label'] = label.gsub(/&/, 'and')
    con['unit']=@unit if @unit
    case type
    when 'cmd'
      cfga << id
      con['cfg'] = [[site, id]]
    when 'act'
      con['exec'] = [[site, id]]
    else
      con['upd'] = [[site, id]]
    end
    if cmd
      _, mid, post = cmd.split('/')
      if mid
        rtry, cri, = mid.split(':')
        wait = con['wait'] = {}
        if cri
          wait['retry'] = rtry
          wait['until'] = spl_cond(cri) { |cond| [site, cond] }
        else
          wait['sleep'] = rtry
        end
        wait['post'] = spl_cmd(post, '&') if post
      end
    end
  end
  mdb["grp_#{site}"] = grp.select! do|_k, v|
    %w(wait goal check).any? { |f| v.key?(f) }
  end
  index.update(grp)
end

# Convert mdb
proj = opt['m']
if proj
  grp = mdb['grp_mcr'] = {}
  get_csv("idb_mcr-#{proj}") do|id, gl, ck|
    con = grp[id] = {}
    con['goal'] = spl_cond(gl) { |e| get_site(e) } if gl && !gl.empty?
    con['check'] = spl_cond(ck) { |e| get_site(e) } if ck && !ck.empty?
  end
  select = []
  get_csv("cdb_mcr-#{proj}") do|id, label, _inv, type, seq|
    if type == 'cap'
      @unit = id
      next
    end
    con = (grp[id] ||= {})
    con['label'] = label.gsub(/&/, 'and')
    con['unit']=@unit if @unit
    con['seq'] = spl_cmd(seq).map do|ary|
      id = ary.join('_')
      ary = index.key?(id) ? ['mcr', id] : ary
      if /%./ =~ ary[1]
        select << ary[1]
        ary[1] = ary[1].sub(/%(.)/, 'X')
      end
      ary
    end if seq && !seq.empty?
  end
  unless select.empty?
    db = {}
    get_csv("db_mcv-#{proj}") do|id, var, list|
      ary = list.to_s.split(' ').map { |str| str.split('=') }
      db[id] = { 'var' => var, 'list' => ary }
    end
    grp = mdb['select'] = {}
    select.each do|str|
      id = str.sub(/%(.)/, 'X')
      con = grp[id] = {}
      dbi = db[$+]
      var = dbi['var'].split(':')
      con['label'] = 'Select Macro'
      sel = con['select'] = {}
      sel['site'] = var[0]
      sel['var'] = var[1]
      op = sel['option'] = {}
      dbi['list'].each do|k, v|
        # For '/S' -> 'S'
        op[k.delete('/')] = str.sub(/%./, v)
      end
    end
  end
end
puts JSON.dump mdb
