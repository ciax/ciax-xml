#!/usr/bin/ruby
module CIAX
  # Add Data Loading feature
  # @data needed
  module JLoad
    def self.extended(obj)
      Msg.type?(obj, Datax, JSave)
    end

    def ext_load
      load
      self
    end

    # Saving data of specified keys with tag
    def save_key(keylist, tag = nil)
      hash = {}
      keylist.each do|k|
        if @data.key?(k)
          hash[k] = get(k)
        else
          warning("No such Key [#{k}]")
        end
      end
      if hash.empty?
        Msg.par_err('No Keys')
      else
        tag ||= (tag_list.max { |a, b| a.to_i <=> b.to_i }.to_i + 1)
        Msg.msg("Status Saving for [#{tag}]")
        output = Hashx.new(self)
        output[@data_name] = hash
        write_json(output.to_j, tag)
      end
      self
    end

    def load(tag = nil)
      base = file_base(tag)
      fname = file_path(tag)
      json_str = ''
      open(fname) do|f|
        verbose { "Loading [#{base}](#{f.size})" }
        f.flock(::File::LOCK_SH)
        json_str = f.read
      end
      if json_str.empty?
        warning(" -- json file (#{base}) is empty at loading")
      else
        data = j2h(json_str)
        verbose { "Version compare [#{data['ver']}] vs. <#{self['ver']}>" }
        if data['ver'] == self['ver']
          @data.deep_update(data[@data_name])
        else
          alert("Version mismatch [#{data['ver']}] should be <#{self['ver']}>")
        end
      end
      self
    rescue Errno::ENOENT
      if tag
        Msg.par_err('No such Tag', "Tag=#{tag_list}")
      else
        warning("  -- no json file (#{base})")
      end
    end

    def tag_list
      Dir.glob(file_path('*')).map do|f|
        f.slice(/.+_(.+)\.json/, 1)
      end.sort
    end
  end
end
