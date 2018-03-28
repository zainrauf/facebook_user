class Api::V1::FacebookLoginController < ApplicationController
  before_action :validate_access_token, :validate_facebook_id, only: [:create]

  def create

    # user = FbGraph2::User.new(params[:facebook_id]).authenticate(params[:access_token])
    # user = FbGraph::User #user.fetch
    begin
      user = FbGraph2::User.me(params[:access_token]).fetch(fields: [:name, :email, :first_name, :last_name, :cover])
    rescue Exception
      render json: {success: false, message: "invalid access token"} and return nil
    end
    if user.email.present?
      users = User.where(:email => user.email)
      if users.present?
        current_user = users.first
        @resource = current_user
        generate_token_with_session_creation
      else
        @user = User.new(:email => user.email, :password => params[:facebook_id],
                         :name => user.name, :access_token => params[:access_token],
                         :profile_url => user.cover, :age => 17,
                         :facebook_id => params[:facebook_id]
        )
        if @user.save
          @user.update_attributes(provider: "facebook")
          @resource = @user
          generate_token_with_session_creation
        else
          render json: {success: false, message: "You were not registered successfully"}
        end
      end

    end

  end

end

private
def user_params
  params.require(:user).permit(:email, :facebook_id, :profile_picture, :gender, :age, :access_token)
end

def validate_access_token
  if params[:access_token].blank?
    render json: {success: false, message: "There is no access token available ", }
  end
end

def validate_facebook_id
  if params[:facebook_id].blank?
    render json: {success: false, message: "There is no facebook id available ", }
  end
end

def generate_token_with_session_creation
  @client_id = SecureRandom.urlsafe_base64(nil, false)
  @token = SecureRandom.urlsafe_base64(nil, false)

  @resource.tokens[@client_id] = {
      token: BCrypt::Password.create(@token),
      expiry: (Time.now + DeviseTokenAuth.token_lifespan).to_i
  }
  # @resource.fcm_token = params[:fcm_token] unless params[:fcm_token].blank?
  @resource.save

  sign_in(:user, @resource, store: false, bypass: true)

  render json: {
      status: 'success',
      data: @resource.as_json(except: [:tokens, :id, :created_at, :updated_at, :is_active, :image, :fb_friends, :device_token, :facebook_id, :access_token])
  }
end