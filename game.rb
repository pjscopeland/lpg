require 'sinatra'
require 'sinatra/base'
require 'curb'
require 'json'
require 'bcrypt'

set port: 4567
# This is where the account server is
set account_server_root: 'localhost:4568'

enable :sessions
set session_secret: ENV['SESSION_SECRET']

before do
  unless session[:authorized?] || request.path == '/authorize'
    halt erb(:'authorize.html', layout: :'layout.html')
  end
end

post '/authorize' do
  correct_password = BCrypt::Password.new("$2a$10$GQe8kpM/haQmtJ9lu.MVPOPgSuTTMI.NKa9NjqJuH0XZgqGvcJCca")
  session[:authorized?] = correct_password == params[:password]
  redirect back
end

get '/deauthorize' do
  session[:authorized?] = false
  redirect to('/')
end

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

def to_sentence(bets)
  case bets.count
  when 0 then ''
  when 1 then bets[0]
  when 2 then bets.join ' or '
  else [bets[0..-2].join(', '), bets[-1]].join(', or ')
  end
end

get '/' do
  if current_user
    erb :'index.html', layout: :'layout.html'
  else
    erb :'login.html', layout: :'layout.html'
  end
end

# Validate card on the account server. Set the current_user on the session on success
post '/login' do
  http = Curl.post("#{settings.account_server_root}/members/validate", params)
  if http.status == '200 OK'
    self.current_user = JSON.parse(http.body_str)
  end
  redirect to('/')
end

# Clear the current_user and return to the root page
get '/logout' do
  self.current_user = nil
  redirect to('/')
end

# Play the game.
post '/play' do
  # The amount bet by the user
  @amount = params['game']['amount'].to_i
  # The numbers the user bet on
  @bets = params['game']['bet_on'].keys.map(&:to_i)
  # The odds of the user winning. Rational#to_s comes up as 'x/y' and it's more accurate
  odds = Rational(@bets.count, 6)
  # The net amount the user stands to gain
  payout = (@amount / odds).to_i - @amount
  # The number the dice actually came up with
  @roll = rand(6) + 1
  # Did the user win?
  @success = @bets.include? @roll
  # Credit or debit the user's account
  if @success
    http = Curl.post("#{settings.account_server_root}/members/#{current_user['id']}/credit", amount: payout)
  else
    http = Curl.post("#{settings.account_server_root}/members/#{current_user['id']}/debit", amount: @amount)
  end
  # And reload their balance
  self.current_user = JSON.parse(http.body_str)
  erb :'result.html', layout: :'layout.html'
end
