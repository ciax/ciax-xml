#!/usr/bin/ruby
# IDB,CDB CSV(CIAX-v1) to MDB
# alias c2m
require 'optparse'
require 'json'
abort 'Usage: csv2mdb -m(proj) [sites]' if ARGV.size < 1
opt = ARGV.getopts('m:')

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

def spl_cond(line)
  line.split('&').map do|s|
    site, cond = yield s
    case cond
    when /[~!=^]/
      ope = { '~' => 'match', '!' => 'not', '=' => 'equal', '^' => 'unmatch' }[$&]
      ary = [ope, $', site, $`]
      ary << @skip if @skip
      ary
    when '*', '', nil
      nil
    else
      abort "IDB: NO operator in #{cond}"
    end
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
      next if /^[a-zA-Z0-9]/ !~ line
      yield line.chomp.split(',')
    end
  end
end

mdb = {}
index = {}
# Convert device
ARGV.each do|site|
  grp = {}
  get_csv("idb_#{site}") do|id, goal, check|
    con = grp["#{site}_#{id}"] = {}
    con['goal'] = spl_cond(goal) { |cond| [site, cond] } if goal && !goal.empty?
    con['check'] = spl_cond(check) { |cond| [site, cond] } if check && !check.empty?
  end
  get_csv("cdb_#{site}") do|id, label, _inv, type, cmd|
    next if type == 'cap'
    con = (grp["#{site}_#{id}"] ||= {})
    con['label'] = label.gsub(/&/, 'and')
    con['exec'] = [[site, id]]
    if cmd
      pre, mid, post = cmd.split('/')
      if mid
        rtry, cri, *upd = mid.split(':')
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
if proj = opt['m']
  grp = mdb['grp_mcr'] = {}
  get_csv("idb_mcr-#{proj}") do|id, goal, check|
    con = grp[id] = {}
    con['goal'] = spl_cond(goal) { |elem| get_site(elem) } if goal && !goal.empty?
    con['check'] = spl_cond(check) { |elem| get_site(elem) } if check && !check.empty?
  end
  select = []
  get_csv("cdb_mcr-#{proj}") do|id, label, _inv, type, seq|
    next if type == 'cap'
    con = (grp[id] ||= {})
    con['label'] = label.gsub(/&/, 'and')
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
      db[id] = { 'var' => var, 'list' => "#{list}".split(' ').map { |str| str.split('=') } }
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
        op[k] = str.sub(/%./, v)
      end
    end
  end
end
puts JSON.dump mdb
