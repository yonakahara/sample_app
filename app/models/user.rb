class User < ApplicationRecord
    # 仮想の属性を作成（dbに保存されない）
    attr_accessor :remember_token
    before_save {self.email = email.downcase}
    validates(:name, presence: true, length: { maximum: 50 })
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
    validates(:email, presence: true, length: { maximum: 255 }, 
        format: { with: VALID_EMAIL_REGEX }, 
        uniqueness: true
    )
    has_secure_password
    validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

    # 渡された文字列のハッシュを戻す
    def User.digest(string)
        cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                      BCrypt::Engine.cost
        BCrypt::Password.create(string, cost: cost)
    end

    # ランダムなトークンを返す
    def User.new_token
        SecureRandom.urlsafe_base64
    end

    def remember
        self.remember_token = User.new_token
        # update_attributeを使って、validationをスキップして属性を更新する
        # remember_digest属性にdigestされたremember_tokenを格納する
        update_attribute(:remember_digest, User.digest(remember_token))
    end

    def authenticated?(remember_token)
        return false if remember_digest.nil?
        BCrypt::Password.new(remember_digest).is_password?(remember_token)
    end

    def forget
        update_attribute(:remember_digest, nil)
    end


end
