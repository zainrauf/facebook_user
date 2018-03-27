class Api::V1::FacebookLoginController < ApplicationController
  before_action :validate_access_token, :validate_facebook_id, only: [:create]

  def create

    user = FbGraph2::User.new('params[:facebook_id]').authenticate('params[:access_token]')
    user.fetch
    if user.email.blank?
      users = User.where(:email => user.email)
      if users.present?
        current_user = users.first
        @resource = current_user
        # generate_token_with_session_creation
      else
        @user = User.build(User.new(:email => user.email, :password => params[:facebook_id],
                                    :name => user.name, :access_token => params[:access_token],
                                    :profile_url => user.cover, :age => params[:age],
                                    :facebook_id => params[:facebook_id]
        ))
        if @user.save
          @resource = @user
          # generate_token_with_session_creation
           render json: {success: true, message: "You are registered successfully", data: @user}
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
    render json: {success: false, message: "There is no access token available ",}
  end
end
def validate_facebook_id
  if params[:facebook_id].blank?
    render json: {success: false, message: "There is no facebook id available ",}
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

  sign_in(:user, @resource, store: false, bypass: false)

  render json: {
      status: 'success',
      data: @resource.as_json(except: [:tokens, :id, :created_at, :updated_at, :is_active, :image, :fb_friends, :device_token])
  }
end