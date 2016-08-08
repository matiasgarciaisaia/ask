class User < ApplicationRecord
  has_many :channels
  has_many :quizzes

  # Include default devise modules. Others available are:
  # :lockable and :timeoutable
  devise  :database_authenticatable, :registerable,
          :recoverable, :rememberable, :trackable, :validatable,
          :omniauthable, :confirmable
end
