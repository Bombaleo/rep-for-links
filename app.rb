require 'sinatra'
require 'sinatra/activerecord'
require 'dotenv'
require './models/user'
require './models/url'
require 'rest-client'
require './config/environments'
require 'rubygems'
require 'json'

Dotenv.load

CLIENT_ID = ENV['GH_BASIC_CLIENT_ID']
CLIENT_SECRET = ENV['GH_BASIC_SECRET_ID']

use Rack::Session::Pool, :cookie_only => false

def authenticated?
  session[:username]
end

get '/' do
	if authenticated?
  	redirect '/submit'
  else
  	erb :auth, :locals => {:client_id => CLIENT_ID}
  end
end

get '/callback' do
  session_code = request.env['rack.request.query_hash']['code']
  access_token = session[:access_token]
  result = RestClient.post('https://github.com/login/oauth/access_token',
                        {:client_id => CLIENT_ID,
                         :client_secret => CLIENT_SECRET,
                         :code => session_code},
                         :accept => :json)
  session[:access_token] = JSON.parse(result)['access_token']
  access_token = session[:access_token]
  begin
    auth_result = RestClient.get('https://api.github.com/user',
                                 {:params => {:access_token => access_token},
                                  :accept => :json})
  rescue => e
    session[:access_token] = nil
  end
  auth_result = JSON.parse(auth_result)
  @user = User.find_or_create_by(name: auth_result['login'], password: auth_result['login'] )
  session[:username] = auth_result['login']
  @user.save
  redirect "/"
end

get '/submit' do
  @user = User.find_by(name: session[:username])
  erb :index
end

post '/submit' do
  @user = User.find_by(params[:user])
  puts "#{@user}"
  return (erb :error, :locals => {:message => 'This user does not exist, please authorizate'}) unless @user
	if @user.save
		session[:username] = @user.name
    erb :index
	else
		'Sorry, there was an error!'
	end
end

post '/delurl' do
  @user = User.find_by(name: params[:name])
  @user.urls.find_by(link: params[:link]).destroy
  erb :index
end

post '/addurl' do
  @user = User.find_by(name: params[:name])
  puts @user.name
  @user.urls.create(params[:url])
  erb :index
end

get '/signup' do
  erb :signup
end

post '/signup' do
  @user = User.find_by(name: params[:user]["name"])
  return erb :error, :locals => {:message => 'User with this name olready exist.'} if @user
  @user = User.create(params[:user])
  if @user.save
		access_token = session[:access_token]
    erb :index
	else
		'Sorry, there was an error!'
	end
end

get '/logout' do
	session[:username] = nil
	redirect '/'
end
