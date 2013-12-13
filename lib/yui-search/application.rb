# -*- encoding: utf-8 -*-

require 'groonga'
require 'digest/md5'

module YuiSearch
  class Application < Sinatra::Base
    def initialize
      super
      @database = Groonga::Database.open('db/data.groonga')
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
      queries.each do |word|
        snippet.add_keyword(word)
      end

      Groonga['Entries'].select do |record|
        target = record.match_target do |match_record|
          (match_record['title'] * 100) | (match_record['body'] * 10) | match_record['permalink']
        end
        queries.map do |q|
          target =~ q
        end
      end.each do |entry|
        image = entry.key['image']
        thumbnail = "http://static.s5r.jp/images/#{Digest::MD5.hexdigest(image)}.jpg" if image and image.include? 'jpg'
        entries << {
          :permalink  => entry.key['permalink'],
          :title      => entry.key['title'],
          :thumbnail  => thumbnail,
          :created_at => entry.key['created_at'],
          :snippets   => snippet.execute(entry.key['body']).join('<br />'),
        }
        break if entries.size > count
      end

      json entries
    end
  end
end

