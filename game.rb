require 'sinatra'
require 'sinatra/base'
require 'curb'
require 'json'

set port: 4567
set account_server_root: 'localhost:4568'

enable :sessions

def current_user
  session[:current_user]
end

def current_user=(user)
  if user
    session[:current_user] = user
  else
    session.delete(:current_user)
  end
end

get '/' do
  if current_user
    erb :'index.html', layout: :'layout.html'
  else
    erb :'login.html', layout: :'layout.html'
  end
end

post '/login' do
  http = Curl.post("#{settings.account_server_root}/members/#{params[:id]}/validate", params)
  if http.status == '200 OK'
    self.current_user = JSON.parse(http.body_str)
  end
  redirect to('/')
end

get '/logout' do
  self.current_user = nil
  redirect to('/')
end

post '/play' do
  roll = rand(6) + 1
  amount = params['game']['amount'].to_i
  bets = params['game']['bet_on'].keys.map(&:to_i)
  odds = Rational(bets.count, 6)
  gain = (amount / odds).to_i - amount
  @success = bets.include? roll
  if @success
    http = Curl.post("#{settings.account_server_root}/members/#{current_user['id']}/credit", amount: gain)
  else
    http = Curl.post("#{settings.account_server_root}/members/#{current_user['id']}/debit", amount: amount)
  end
  self.current_user = JSON.parse(http.body_str)
  erb :'result.html', layout: :'layout.html'
end
