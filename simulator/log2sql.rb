#!/usr/bin/ruby
require 'json'
# Device simulator SQL generator from Stream Log file
# Internal functions
class LogToSql
  private

  def read_files
    @files.each do |fname|
      pr fname
      open(fname) do |fs|
        yield fs, 1, {}
      end
    end
  end

  def progress(c)
    return unless (c % 10_000).zero?
    return pr '.' unless (c % 100_000).zero?
    pr '*'
    true
  end

  def divide(c, rec)
    return unless (c % 500_000).zero?
    commit(rec, c)
    puts 'begin;'
  end

  def commit(rec, c)
    insert(rec)
    puts 'commit;'
    pr "<commit(#{format('%.1f', c.to_f / 1_000_000)}M)>"
  end

  def count(c, n, rec)
    return if n > 0 && c > n && rec.empty?
    progress(c) && divide(c, rec)
    c + 1
  end

  # Making record Hash (ch => current hash)
  def mk_record(line, rec)
    ch = inspection(line)
    case ch['dir']
    when 'snd'
      item_snd(ch, rec)
    when 'rcv'
      item_rcv(ch, rec)
    else
      pr 'no match'
    end
  end

  def item_snd(ch, rec)
    insert(rec)
    pick(%i(time id ver cmd), ch, rec)
    rec[:snd] = ch['base64']
    self
  end

  def item_rcv(ch, rec)
    if rec.key(:rcv)
      pr 'rcv duplicated'
    elsif corresponding?(%i(id ver cmd), ch, rec)
      rec[:rcv] = ch['base64']
      rec[:dur] = mk_dur(ch, rec)
      insert(rec)
    end
    self
  end

  def pick(ks, ch, rec = {})
    ks.each_with_object(rec) { |k, h| h[k] = ch[k.to_s] }
  end

  def corresponding?(ks, ch, rec)
    ks.all? { |k| rec[k] == ch[k.to_s] }
  end

  def mk_dur(ch, rec)
    (ch.delete('time').to_i - rec[:time].to_i).to_f / 1000.0
  end

  # Making insert statement
  def keys_vals(rec)
    @field.each_with_object([[], []]) do |src, dst|
      next unless rec.key?(key = src[0])
      dst[0] << key
      dst[1] << conv(rec[key], src[1])
    end
  end

  def conv(str, type)
    case type
    when :s
      "'#{str}'"
    when :i
      str.to_i
    when :f
      str.to_f
    end
  end

  # Print STDERR
  def pr(text = nil)
    len = text.to_s.length
    if len > 1
      STDERR.puts "\033[1;34m#{text}\33[0m"
    elsif len == 1
      STDERR.print text
    else
      STDERR.puts
    end
    false
  end
end

# Data conversion for old format
class LogToSql
  private

  # Convert from old format to latest
  def inspection(line)
    ch = {}
    if line =~ /(^[0-9\.]+).*(\{.*\})/
      ch['time'] = Regexp.last_match(1).delete('.')
      line = Regexp.last_match(2)
    end
    modify(ch.update(JSON.parse(line)))
  end

  def modify(ch)
    time = ch['time']
    ch['time'] = time.delete('.').to_i if time.is_a? String
    chg_key(ch, 'data', 'base64')
    chg_key(ch, 'cid', 'cmd')
    ch
  end

  def chg_key(ch, key1, key2)
    ch[key2] = ch.delete(key1) if ch.key?(key1)
  end
end

# Public functions
class LogToSql
  # record includes both command and response data
  # [ { :time => time, :id => id, :ver => ver,
  #     :snd => base64, :rcv => base64, :dur => msec } ]
  def initialize(id)
    id = (id == '-a') ? '' : id.to_s
    id = "{#{id}}" if id.include?(',')
    @files = Dir.glob(ENV['HOME'] + "/.var/log/**/stream_#{id}*.log").sort
    # field name vs data type table (:i=Integer, :s=String, :f=Float)
    @field = { time: :i, id: :s, ver: :i, cmd: :s, snd: :s, rcv: :s, dur: :f }
  end

  def create
    names = @field.keys.join(',')
    puts "create table stream (#{names},primary key(time));"
    self
  end

  def drop
    puts 'drop table if exists stream;'
    self
  end

  # pick up n lines each
  def transaction(n = 0)
    read_files do |fs, c, rec|
      puts 'begin;'
      while (line = fs.gets)
        mk_record(line, rec)
        c = count(c, n, rec) || break
      end
      commit(rec, c)
    end
    self
  end

  def insert(rec)
    return if rec.empty?
    ks, vs = keys_vals(rec).map { |ary| ary.join(',') }
    puts "insert or ignore into stream (#{ks}) values (#{vs});"
    rec.clear
    self
  end
end

abort 'Usage: log2sql (-a,c) [id,..] (lines)' if ARGV.empty?
id = ARGV.shift
if id == '-c'
  clr = true
  id = ARGV.shift
end
num = ARGV.shift.to_i
ARGV.clear

l2s = LogToSql.new(id)
l2s.drop.create if clr
l2s.transaction(num)
