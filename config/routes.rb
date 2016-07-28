Rails.application.routes.draw do
  resources :channels
  resources :surveys do
    member do
      get :start
    end
  end
  resources :questions
  resources :quizzes
  resources :respondents
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'quizzes#index'
  post 'broker/callback' => 'broker#callback'
end
