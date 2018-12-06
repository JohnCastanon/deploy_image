require "sinatra"
require 'data_mapper'
require 'stripe'
require 'sinatra/flash'

require_relative "authentication.rb"


set :publishable_key, 'pk_test_LnHwpxM8WB49CysYYjAYxFnT'
set :secret_key, 'sk_test_lpv6IRAJZ26PTaXG5hbCwg2S'

Stripe.api_key = settings.secret_key

# need install dm-sqlite-adapter
# if on heroku, use Postgres database
# if not use sqlite3 database I gave you
if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end

class Items
  include DataMapper::Resource

  property :id, Serial
  property :item, Text
  property :description, Text
  property :seller, Text
  property :condition, Text
  property :imgData, Text
  property :price,Text

  #fill in the rest
end

DataMapper.finalize
User.auto_upgrade!
Items.auto_upgrade!



#make an admin user if one doesn't exist!
if User.all(administrator: true).count == 0
  u = User.new
  u.email = "admin@admin.com"
  u.password = "admin"
  u.administrator = true
  u.save

end

def reg_user 
if !current_user || current_user.pro || current_user.administrator
  redirect "/"
end

end 



def pro_user 
if current_user.pro
    redirect "/"
end

end 




def admin
  if !current_user || !current_user.administrator
    redirect "/"
  end
end


#make an admin user if one doesn't exist!
if User.all(administrator: true).count == 0
  u = User.new
  u.email = "admin@admin.com"
  u.password = "admin"
  u.administrator = true
  u.save
end





#the following urls are included in authentication.rb
# GET /login
# GET /logout
# GET /sign_up

# authenticate! will make sure that the user is signed in, if they are not they will be redirected to the login page
# if the user is signed in, current_user will refer to the signed in user object.
# if they are not signed in, current_user will be nil

get "/" do
  @Item = Items.all
  erb :index
end

get "/reviews" do

  erb :reviews
end

get "/ad/:id" do
    
    ma = params[:id]
    thing = Items.get(ma)
    @hi = thing
    erb :ad
  
end

get "/showreviews" do

  erb :showreviews
end

get "/admin" do

  authenticate!
  admin

  erb :admin
end


get "/items" do
  authenticate!

  @Item = Items.all

  
    erb :items

end

get "/selling" do
  erb :selling
end 

post "/seller/create" do
    authenticate!
     if params["description"]!="" && params["price"]!=""
      product = Items.new
      product.item = params["Item"]
      product.description = params["description"]
      product.condition = params["option"]
      product.price = params["price"]
      product.seller = current_user.email
      product.save

      @filename = params[:file][:filename]
      file = params[:file][:tempfile]
      File.open("./public/images/items/#{@filename}"+(product.id).to_s, 'wb') do |f|
      f.write(file.read)
      end
      
      product.imgData="/images/items/#{@filename}"+(product.id).to_s
      product.save
        flash[:success]="Hooray, Flash is working!."
        redirect "/items" 

     else
      flash[:error]="Item can not be added.Please make sure item's infomration is set." 
      redirect "/selling" 
    end

end

get "/profile" do
  erb :profile

end 

get "/upgrade" do
    authenticate!
    reg_user 

    erb :pay

end

get "/search" do 
    value=params["search"]
    @value=Items.all(:item.gte => value)
    erb :search
end 


get "/form" do
  
  erb :form
end


post '/save_image' do

  @filename = params[:file][:filename]
  file = params[:file][:tempfile]
    File.open("./public/images/items/#{@filename}", 'wb') do |f|
    f.write(file.read)
  end

  erb :show_image
end




post "/charge" do
    # Amount in cents
  @amount = 500

  customer = Stripe::Customer.create(
    :email => current_user.email,
    :source  => params[:stripeToken]
  )

  charge = Stripe::Charge.create(
    :amount      => @amount,
    :description => 'Sinatra Charge',
    :currency    => 'usd',
    :customer    => customer.id
  )

  current_user.pro = true;
  current_user.save
    erb :charge

end









