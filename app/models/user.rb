class User < ApplicationRecord
    has_many :microposts, dependent: :destroy

    # relationshipsのforeign keyが典型的ではないので以下のような書き方になる。
    has_many :active_relationships, class_name:  "Relationship",
      foreign_key: "follower_id",
      dependent:   :destroy

    has_many :passive_relationships, class_name:  "Relationship",
       foreign_key: "followed_id",
       dependent:   :destroy
    
    # following配列の元がfollowed idの集合であることを明示的に伝える。（つまりfollowingがfollowedsの代わりになっている）
    has_many :following, through: :active_relationships, source: :followed
    has_many :followers, through: :passive_relationships, source: :follower
    
    # 仮想の属性を作成（dbに保存されない）
    attr_accessor :remember_token, :activation_token, :reset_token
    before_save :downcase_email
    before_create :create_activation_digest
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

    def authenticated?(attribute, token)
        # なんのダイジェストが欲しいかを引数によって分けたいのでsendメソッド（メタプログラミング）
        digest = self.send("#{attribute}_digest")
        return false if digest.nil?
        BCrypt::Password.new(digest).is_password?(token)
    end

    def forget
        update_attribute(:remember_digest, nil)
    end

    def activate
        update_attribute(:activated, true)
        update_attribute(:activated_at, Time.zone.now)
    end

    def send_activation_email
        UserMailer.account_activation(self).deliver_now
    end

    def create_reset_digest
        self.reset_token = User.new_token
        update_attribute(:reset_digest, User.digest(reset_token))
        update_attribute(:reset_sent_at, Time.zone.now)
    end

    def send_password_reset_email
        UserMailer.password_reset(self).deliver_now
    end

    def password_reset_expired?
        # <: 早い
        reset_sent_at < 2.hours.ago
    end

    def feed
        # スケール性を考慮してSQLのサブセレクト（サブクエリ）を適用している
        following_ids = "SELECT followed_id FROM relationships
                        WHERE follower_id = :user_id"
        Micropost.where("user_id IN (#{following_ids})
                        OR user_id = :user_id", user_id: id)
    end

    # ユーザーをフォローする
    def follow(other_user)
        following << other_user
    end

    # ユーザーをフォロー解除する
    def unfollow(other_user)
      active_relationships.find_by(followed_id: other_user.id).destroy
    end

    # 現在のユーザーがフォローしてたらtrueを返す
    def following?(other_user)
      following.include?(other_user)
    end

    # private内のメソッドは外部に公開されず、userClassの中でしか使えない。
    private

        def downcase_email
            self.email = email.downcase
        end

        def create_activation_digest
            # cookiesを使うために作ったメソッドnew_tokenやdigestを流用
            self.activation_token  = User.new_token
            # callbackで保存されるので、rememberの時みたいにupdate_attributeを使う必要はない
            self.activation_digest = User.digest(activation_token)
        end



end
