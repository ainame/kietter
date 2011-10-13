# -*- coding: utf-8 -*-
require 'sinatra/base'
require 'padrino-helpers'
require 'openssl'
require 'dalli'
require 'slim'

class MyApp < Sinatra::Base
  register Padrino::Helpers
  configure do 
    cache = Dalli::Client.new(ENV['MEMCACHE_SERVERS'],
                              :username => ENV['MEMCACHE_USERNAME'],
                              :password => ENV['MEMCACHE_PASSWORD'],
                              :expires_in => 60)
    set :cache, cache
    set :public_folder, File.dirname(__FILE__) + '/public'
    Slim::Engine.set_default_options :pretty => true
    KEY = "key_list"
  end

  get '/' do 
    @list = []
    response = settings.cache.get(KEY)
    if response
      key_list = response.split(",").delete_if{|x| x == ""}
      hash = settings.cache.get_multi(key_list)
      new_key_list = hash.select{|v| v if v.to_s != ""}.keys.join(",")
      @list =  hash ? hash.values : []
      response = settings.cache.set(KEY,new_key_list)
    end
    slim :index
  end

  post '/submit' do 
    value = params["text"]
    key = OpenSSL::Random.random_bytes(16).unpack("H*")[0] 
    settings.cache.set(key, value)
    list = settings.cache.get(KEY)
    list = list.nil? ? key : list + "," + key  
    settings.cache.set(KEY,list)

    redirect '/'
  end

  run! if app_file == $0 
end

