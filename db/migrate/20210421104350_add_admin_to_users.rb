class AddAdminToUsers < ActiveRecord::Migration[6.0]
  def change
    # default:falseにすることで、普通はadminになれないことを明示的に開発者やrailsに示す
    add_column :users, :admin, :boolean, default: false
  end
end
