class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  include DeviseTokenAuth::Concerns::User
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :omniauth_providers => [:facebook]


  def self.find_for_oauth(auth)
    puts "****************************______________***************"
    puts auth
    puts "****************************______________***************"
    puts auth.info.email
    puts auth.info.name
    
    user = User.where(uid: auth.uid, provider: auth.provider).first

    unless user
      user = User.create(
          uid: auth.uid,
          provider: auth.provider,
          email: auth.info.email,
          name: auth.info.name,
          password: auth.uid,
          profile_url: auth.info.image,
          access_token: auth.credentials.token,
          tokens: auth.credentials
      )
    end

    user

  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  private

  def self.dummy_email(auth)
    "#{auth.uid}-#{auth.provider}@example.com"
  end
end
