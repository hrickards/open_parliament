require 'bundler'
Bundler.require
require 'open-uri'
require 'pp'
require 'fileutils'

include Mongo

Cachy.cache_store = Redis.new
Mongoid.load! "config/mongoid.yml", :development
DB = MongoClient.new['parliament']

require_relative 'app/helpers'
require_relative 'app/models/bill'
require_relative 'app/models/person'

LIMIT = 40

module OpenParliament
  class Api < Grape::API
    use Rack::JSONP
    version 'v1', using: :header, vendor: 'open_parliament'
    format :json

    before do
      header['Access-Control-Allow-Origin'] = '*'
      header['Access-Control-Request-Method'] = '*'
      header["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
    end

    resources :bills do
      desc "Return a list of all bills"
      params do
        optional :query, type: String, desc: "A category to search for."
        optional :limit, type: Integer, desc: "Maximum number of results to return."
        optional :fields, type: Array, desc: "A list of fields to return data for."
      end
      get do
        Bill.search params[:query], (params[:limit] || LIMIT), params[:fields]
      end

      desc "Return full details of a single bill"
      params do
        requires :slug, type: String, desc: "Slug (machine-readable name) of the bill. Generally a lowercase version of the base title with spaces replaced by underscores."
      end
      get ':slug' do
        Bill.find_by_slug params[:slug]
      end

      desc "Vote on a single bill"
      params do
        requires :slug, type: String, desc: "Slug (machine-readable name) of the bill. Generally a lowercase version of the base title with spaces replaced by underscores."
        requires :type, type: Integer, desc: "The type of vote given: 1 for positive, 0 for negative"
      end
      put ':slug' do
        Bill.find_by_slug(params[:slug]).vote params[:type]
      end
    end

    add_swagger_documentation base_path: 'http://localhost:9292/api'
  end
end
