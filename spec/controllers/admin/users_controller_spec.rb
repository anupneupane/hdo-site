require 'spec_helper'

describe Admin::UsersController do
  let(:user)    { User.make! }
  before(:each) { sign_in user }

  it 'can show index' do
    get :index

    assigns(:users).should == [user]
  end

  it 'can show a user' do
    get :show, id: user

    assigns(:user).should == user
    response.should have_rendered(:show)
  end

  it 'can edit a user' do
    get :edit, id: user

    assigns(:user).should == user
    response.should have_rendered(:edit)
  end

  it 'can update a user' do
    put :update, id: user, user: { email: 'hello@example.com' }

    assigns(:user).should == user.reload
    user.email.should == 'hello@example.com'

    response.should redirect_to admin_user_path(user)
  end

  it 'can destroy a user' do
    delete :destroy, id: user

    response.should redirect_to admin_users_path
  end
end
