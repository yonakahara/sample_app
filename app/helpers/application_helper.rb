module ApplicationHelper
# helper module で書いたメソッドは自動的に全てのviewで使えるようになっている！

    # ページごとの完全なタイトルを返します。
    def full_title(page_title = '')
      base_title = "Ruby on Rails Tutorial Sample App"
      if page_title.empty?
        base_title
      else
        page_title + " | " + base_title
      end
    end

end