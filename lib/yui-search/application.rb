# -*- encoding: utf-8 -*-

require 'groonga'

module YuiSearch
  class Application < Sinatra::Base
    def initialize
      super
      @database = Groonga::Database.open('db/data.groonga')
    end

    get '/' do
      redirect 'http://yui-search.com/'
    end

    get '/search' do
      response.headers['Access-Control-Allow-Origin'] = '*'
      query = params['q'] || ''
      queries = query.split(' ')
      count = params['count'] || 100
      entries = []
      snippet = Groonga::Snippet.new(
        :width             => 100,
        :default_open_tag  => "<span class=\"keyword\">",
        :default_close_tag => "</span>",
        :html_escape       => true,
        :normalize         => true,
      )
      query.split.each do |word|
        snippet.add_keyword(word)
      end

      Groonga['Entries'].select do |record|
        queries.map do |q|
          record.body =~ q
        end
      end.each do |entry|
        entries << {
          :permalink => entry.key['permalink'],
          :title     => entry.key['title'],
          :snippets  => snippet.execute(entry.key['body']).join
        }
        break if entries.size > count
      end

      json entries
    end
  end
end

