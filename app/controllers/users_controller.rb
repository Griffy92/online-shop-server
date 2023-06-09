class UsersController < ApplicationController
    skip_before_action :is_authorized, only: [:create, :login, :show]

    def index
        @users = User.all
        render json: @users, include: {orders: {include: {cart_items: {include: {product: {}}}}}}
    end

    def show
        @user = User.find params[:id]
        render json: @user, include: {orders: {include: {cart_items: {include: {product: {}}}}}}
    end
    
    def profile
        render json: @user, include: {orders: {include: {cart_items: {include: {product: {}}}}}}
    end
    
    def create
        @user = User.create user_params
        @token = JWT.encode({user_id: @user.id}, Rails.application.secrets.secret_key_base[0])
        render json: {user: @user, token: @token}, include: {orders: {include: {cart_items: {include: {product: {}}}}}}, :status => :created
    end

    def login
        @user = User.find_by(:email => params[:user][:email])

        if @user && @user.authenticate(params[:user][:password])
            @token = JWT.encode({user_id: @user.id}, Rails.application.secrets.secret_key_base[0])
            render json: {user: @user, token: @token}, include: {orders: {include: {cart_items: {include: {product: {}}}}}}
        else
            render json: { error: "Invalid Credentials"}, :status => :unauthorized
        end
    end

    private

    def user_params
        params.require(:user).permit(:fullname, :email, :password, :address, :admin, :contact_number)
    end
end
