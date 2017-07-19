# require 'rails_helper'

# RSpec.describe Users::OmniauthCallbacksController, type: :controller do
#   describe 'GET complete' do
#     context 'with valid new user' do
#       it 'creates new user and new identity' do
#         request.env['omniauth.auth'] = OmniAuth::AuthHash.new(
#           provider: 'saml',
#           uid: 'johndoe',
#           info: {
#             email: 'johndoe@ualberta.ca',
#             display_name: 'John Doe'
#           }
#         )

#         expect { get :complete, params: { provider: 'saml' } }.to change { User.count }.by(1)
#         user = User.last
#         identity = user.identities.last
#         expect(user.display_name).to eq 'John Doe'
#         expect(user.email).to eq 'johndoe@ualberta.ca'
#         expect(identity.provider).to eq 'saml'
#         expect(identity.uid).to eq 'johndoe'
#         expect(controller).to set_flash[:notice].to(I18n.t('devise.omniauth_callbacks.success', kind: 'saml'))
#         expect(response).to redirect_to(::Sufia::Engine.routes.url_helpers.dashboard_index_path)
#       end
#     end

#     context 'with valid existing user' do
#       it 'uses existing identity if present' do
#         user = create(:omniauth_user, email: 'johndoe@ualberta.ca', provider: 'saml', uid: 'johndoe')

#         request.env['omniauth.auth'] = OmniAuth::AuthHash.new(
#           provider: 'saml',
#           uid: 'johndoe',
#           info: {
#             email: 'johndoe@ualberta.ca'
#           }
#         )

#         expect { get :complete, params: { provider: 'saml' } }.not_to change { User.count }
#         identity = user.identities.last
#         expect(user.email).to eq 'johndoe@ualberta.ca'
#         expect(identity.provider).to eq 'saml'
#         expect(identity.uid).to eq 'johndoe'
#         expect(controller).to set_flash[:notice].to(I18n.t('devise.omniauth_callbacks.success', kind: 'saml'))
#         expect(response).to redirect_to(::Sufia::Engine.routes.url_helpers.dashboard_index_path)
#       end

#       it 'creates a new identity if not present' do
#         user = create(:omniauth_user, email: 'johndoe@ualberta.ca', provider: 'saml', uid: 'johndoe')

#         request.env['omniauth.auth'] = OmniAuth::AuthHash.new(
#           provider: 'facebook',
#           uid: '12345678',
#           info: {
#             email: 'johndoe@ualberta.ca'
#           }
#         )

#         expect { get :complete, params: { provider: 'facebook' } }.not_to change { User.count }
#         identity = user.identities.last
#         expect(user.email).to eq 'johndoe@ualberta.ca'
#         expect(identity.provider).to eq 'facebook'
#         expect(identity.uid).to eq '12345678'
#         expect(controller).to set_flash[:notice].to(I18n.t('devise.omniauth_callbacks.success', kind: 'facebook'))
#         expect(response).to redirect_to(::Sufia::Engine.routes.url_helpers.dashboard_index_path)
#       end
#     end

#     context 'with invalid new user' do
#       it 'Gives error message and does not save user' do
#         request.env['omniauth.auth'] = OmniAuth::AuthHash.new(
#           provider: 'saml',
#           uid: 'johndoe',
#           info: {
#             email: nil
#           }
#         )

#         expect { get :complete, params: { provider: 'saml' } }.not_to change { User.count }
#         expect(controller).to set_flash[:alert].to(I18n.t('login.omniauth_error'))
#         expect(response).to redirect_to(new_user_session_path)
#       end
#     end
#   end
# end
