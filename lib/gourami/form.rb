require_relative "./attributes"
require_relative "./validations"
require_relative "./coercer"

module Gourami
  # Base Form for doing actions based on the attributes specified.
  # This class has to be inherited by different forms, each performing a
  # different action. If needed, #validate method can be overridden if
  # necessary.
  #
  # @example
  #
  #   class LogIn < Gourami::Form
  #
  #     attribute(:username, :type => :string)
  #     attribute(:password, :type => :string)
  #
  #     def validate
  #       unless valid_login?
  #         append_error(:username, :invalid_credentials)
  #       end
  #     end
  #
  #     def perform
  #       User.create(attributes)
  #     end
  #
  #     private
  #
  #     def valid_login?
  #       user = User.first(:username => username)
  #       user && check_password_secure(user.password, password)
  #     end
  #
  #   end
  #
  # @example
  #
  #   class UpdateUser < Gourami::Form
  #
  #     VALID_TYPES = %w[buyer seller]
  #
  #     record(:user, :skip => true)
  #     attribute(:username, :type => :string)
  #     attribute(:first_name, :type => :string)
  #     attribute(:percentage, :type => :integer)
  #     attribute(:type, :type => :string)
  #
  #     def validate
  #       validate_presence(:username)
  #       validate_length(:username, :min => 2, :max => 64)
  #
  #       validate_presence(:first_name)
  #
  #       validate_presence(:percantage)
  #       validate_range(:percentage, :min => 0, :max => 100)
  #
  #       validate_presence(:type)
  #       validate_inclusion(:type, VALID_TYPES)
  #     end
  #
  #     def perform
  #       user.update(attributes)
  #     end
  #
  #   end
  #
  #   # Usage of the new form class:
  #
  #   form = UpdateUser.new({
  #     :user => User.first,
  #     :username => "WeijieWorld",
  #     :first_name => "Weijie",
  #     :percentage => "100",
  #     :type => "buyer"
  #   })
  #
  #   if form.valid?
  #     form.perform
  #     # Do something else
  #   else
  #     # Do something else
  #   end
  #
  class Form

    include Gourami::Attributes
    include Gourami::Validations
    include Gourami::Coercer

  end
end
