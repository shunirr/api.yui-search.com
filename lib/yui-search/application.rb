# -*- encoding: utf-8 -*-

require 'groonga'
require 'digest/md5'
require 'sewell'

module YuiSearch
  class Application < Sinatra::Base
    def initialize
      super
      @database = Groonga::Database.open('db/data.groonga')
    end

    get '/search' do
      response.headers['Access-Control-Allow-Origin'] = '*'
      query = params['q'] || ''
      page  = (params['page']  || '1' ).to_i
      count = (params['count'] || '10').to_i

      page  = 1  if page <= 0
      count = 10 if count <= 0

      snippet = Groonga::Snippet.new(
        :width             => 200,
        :default_open_tag  => "<span class=\"keyword\">",
        :default_close_tag => "</span>",
        :html_escape       => true,
        :normalize         => true,
      )
      query.split(' ').each do |word|
        snippet.add_keyword(word)
      end
      
      selected_entries = Groonga['Entries'].select(
          Sewell.generate(query, %w{title body})
      )

      result = {}
      if (page - 1) * count < selected_entries.size then
        entries = []
        paginated_entries = selected_entries.paginate(
            [["_score", :desc]],
            :page => page,
            :size => count)

        result['total_page_count'] = paginated_entries.n_pages
        result['total_count']      = selected_entries.size

        paginated_entries.each do |entry|
          image = entry.image
          if image and image.include? 'jpg' then
            thumbnail = "http://static.s5r.jp/images/#{Digest::MD5.hexdigest(image)}.jpg"
          end

          snippets = ""
          if entry.site == Groonga['Sites']['http://www.kasi-time.com']
            result['info'] = entry.title
          else
            snippets = snippet.execute(entry.body).join('<br />')
            entries << {
              :permalink  => entry.permalink,
              :title      => entry.title,
              :thumbnail  => thumbnail,
              :created_at => entry.created_at,
              :snippets   => snippets
            }
          end
        end

        result['entries'] = entries
      end

      json result
    end
  end
end

