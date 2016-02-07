require 'sinatra'
require 'sinatra/base'

get '/' do
  erb :'index.html'
end
