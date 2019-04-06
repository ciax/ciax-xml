#!/usr/bin/env ruby
require 'libxmldoc'
require 'libdbcache'
module CIAX
  # Db::Index class is for read only databases
  #   which holds all the items of database.
  # Key for sub structure(Hash,Array) will be symbol (i.e. :data, :list, :dic..)
  # set() generates HashDb
  # Cache is available
  module Db
    class Item < Hashx # DB Item
      def pick(ary = [])
        super(%i(layer version) + ary).update(dbi: self)
      end
    end

    # DB Index
    class Index < Hashx
      attr_reader :disp_dic
      def initialize(type)
        super()
        verbose { 'Initiate Db' }
        @type = type
        @cache = Cache.new(type)
        _get_disp_dic
        @argc = 0
      end

      def list
        @disp_dic.valid_keys
      end

      # Reduce valid_keys with parameter Array
      def reduce(ary = [])
        unless ary.empty?
          ary &= list
          list.replace(ary)
        end
        self
      end

      def get(id)
        ref(id) || id_err(id, @type, @disp_dic)
      end

      # return Db::Item
      # Order of file reading: type-id.mar -> type-id.xml (processing)
      def ref(id)
        if @disp_dic.valid?(id)
          self[id] || __get_db(id) { |docs| _doc_to_db(docs.get(id)) }
        else
          warning('No such ID [%s]', id)
          false
        end
      end

      private

      # Returns Hash
      def _doc_to_db(doc)
        Item.new(doc[:attr]).update(layer: layer_name)
      end

      def _get_disp_dic(sufx = nil)
        # @disp_dic is Display
        lid = ['list', sufx].compact.join('_')
        # Show site list
        # &:disp_dic = { |e| e.disp_dic }
        @disp_dic = __get_db(lid, &:disp_dic)
      end

      def __get_db(id)
        @cache.get(id) do
          ___load_docs(id)
          verbose { "Building DB (#{id})" }
          self[id] = ___validate_repl(yield(@docs))
        end
      end

      # counter must not remain
      def ___validate_repl(db)
        res = db.deep_search('\$[_a-z]')
        return db if res.empty?
        cfg_err("Counter remained at [#{res.join('/')}]")
      end

      def ___load_docs(id)
        verbose { "Cache/Checking @docs (#{@type})" }
        if @docs
          verbose { "Cache/XML files are Already read (#{id}) [#{@type}]" }
          false
        else
          verbose { "Reading XML (#{@type}-#{id})" }
          @docs = _new_docs
        end
      end

      def _new_docs
        Xml::Doc.new(@type)
      end
    end
  end
end
