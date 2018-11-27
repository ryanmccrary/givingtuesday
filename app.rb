require 'sinatra'
if Sinatra::Base.development?
  require 'pry'
  require 'dotenv'
  Dotenv.load
end
require 'stripe'
require 'mail'
require_relative 'database'

Database.initialize

set :publishable_key, ENV['PUBLISHABLE_KEY']
set :secret_key, ENV['SECRET_KEY']
enable :sessions

Stripe.api_key = settings.secret_key

Mail.defaults do
  delivery_method :smtp, { :address   => "smtp.sendgrid.net",
                           :port      => 587,
                           :domain    => ENV['SENDGRID_DOMAIN'],
                           :user_name => ENV['SENDGRID_USER'],
                           :password  => ENV['SENDGRID_PW'],
                           :authentication => 'plain',
                           :enable_starttls_auto => true }
end

get '/' do
  @donations = Donation.all
  @total = Donation.all.sum(:amount) / 100
  @percent = (@total / 10).to_f.round

  erb :index
end

post '/charge' do
  @donation = Donation.create(
    amount: params[:donation_amount],
    customer: params[:email]
    )
  donation = @donation

  customer = Stripe::Customer.create(
    email: params[:email],
    card: params[:token_id]
  )

  begin
    Stripe::Charge.create(
      amount: @donation.amount,
      description: "Giving Tuesday",
      currency: 'usd',
      customer: customer.id
    )

   session[:id] = @donation.id
  rescue Stripe::CardError => e
    body = e.json_body
    session[:error] = body[:error][:message]
    halt 500
  end
end
  mail = Mail.deliver do

  to customer.email
  from 'Ryan McCrary <ryan@goattrips.org>'
  subject 'Giving Tuesday!'
    text_part do
      body "Thanks so much for being a part of GOAT's Giving Tuesday campaign! We're continually blown away by the generosity of the community around GOAT and the kids we serve. Thanks for giving the gift of the outdoors and changing a student's life.
      We'd love to buy you a coffee as a way of saying thanks! If you're interested, you can head over to our partner cafe, Mountain Goat in Greenville any time this week and show our staff this email for a free coffee drink!
      Thanks again!

      -The GOAT team
      "
    end
  end

  halt 200
end
