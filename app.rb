# -*- coding: utf-8 -*-
require 'sinatra/base'
require 'padrino-helpers'
require 'openssl'
require 'dalli'
require 'slim'
require 'cgi'
require 'sinatra/reloader' if :development
require 'pp' if :development


class MyApp < Sinatra::Base
  register Padrino::Helpers
  configure do 
    cache = Dalli::Client.new(nil, { :expires_in => 60})
    set :cache, cache
    set :public_folder, File.dirname(__FILE__) + '/public'
    Slim::Engine.set_default_options :pretty => true
    KEY = "list"
  end

  get '/' do 
    response = settings.cache.get(KEY)
    @list = []
    unless response.nil?
      key_list = response.split(",").delete_if{|x| x == ""}
      new_key_list = ""
      key_list.each do |key|
        if value = settings.cache.get(key)
          @list.push value
          new_key_list = new_key_list + "," + key
        end
      end
      response = settings.cache.set(KEY,new_key_list)
    end
    
    slim :index
  end

  post '/submit' do 
    value = CGI.escape params["text"]
    id = OpenSSL::Random.random_bytes(16).unpack("H*")[0] 
    settings.cache.set(id, value)
    list = settings.cache.get(KEY)
    if list.nil?
      list = id
    else
      list = list + "," + id
    end
    
    settings.cache.set(KEY,list)

    redirect '/'
  end

  run! if app_file == $0 
end

