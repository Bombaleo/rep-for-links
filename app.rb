require 'sinatra'
require 'sinatra/activerecord'
require 'dotenv'
require './models/user'
require './models/url'
require 'rest-client'
require './config/environments'
require 'rubygems'
require 'json'
require 'logger'

Dotenv.load

CLIENT_ID = ENV['GH_BASIC_CLIENT_ID']
CLIENT_SECRET = ENV['GH_BASIC_SECRET_ID']

URL_TO_GET_TOKEN = 'https://github.com/login/oauth/access_token'.freeze
URL_API_GITHUB_USER = 'https://api.github.com/user'.freeze

SIGN_UP_ERROR = 'User with this name olready exist.'.freeze
SIGN_IN_ERROR = 'This user does not exist, please authorizate.'.freeze

logger = Logger.new('logfile.log')

use Rack::Session::Pool, cookie_only: false

def authenticated?
  session[:username]
end

get '/' do
  redirect '/submit' if authenticated?
  erb :auth, locals: { client_id: CLIENT_ID }
end

get '/callback' do
  session_code = request.env['rack.request.query_hash']['code']
  result = RestClient.post(URL_TO_GET_TOKEN,
                        { client_id: CLIENT_ID,
                         client_secret: CLIENT_SECRET,
                         code: session_code },
                         accept: :json)
  session[:access_token] = JSON.parse(result)['access_token']
  access_token = session[:access_token]
  begin
    auth_result = RestClient.get(URL_API_GITHUB_USER,
                                 { params: { access_token: access_token },
                                  accept: :json })
  rescue => e
    logger.error "Error authentication with github #{e}}"
    session[:access_token] = nil
  end
  auth_result = JSON.parse(auth_result)
  login = auth_result['login']
  @user = User.find_or_create_by(name: login, password: login)
  session[:username] = login
  @user.save
  redirect '/'
end

get '/submit' do
  @user = User.find_by(name: session[:username])
  erb :index
end

post '/submit' do
  @user = User.find_by(params[:user])
  return (erb :error, locals: { message: SIGN_IN_ERROR }) unless @user
  if @user.save
    session[:username] = @user.name
    erb :index
  else
    'Sorry, there was an error!'
  end
end

post '/deleteurl' do
  @user = User.find_by(name: params[:name])
  @user.urls.find_by(link: params[:link]).destroy
  erb :index
end

post '/appendurl' do
  @user = User.find_by(name: params[:name])
  @user.urls.create(params[:url])
  erb :index
end

get '/signup' do
  erb :signup
end

post '/signup' do
  @user = User.find_by(name: params[:user]['name'])
  return erb :error, locals: { message: SIGN_UP_ERROR } if @user
  @user = User.create(params[:user])
  if @user.save
    session[:username] = @user.name
    erb :index
  else
    'Sorry, there was an error!'
  end
end

get '/logout' do
  session[:username] = nil
  redirect '/'
end
