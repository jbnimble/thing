module AuthMacros
  def log_in(attributes = {})
    if attributes[:instructor]
      @_current_user = build(:instructor, attributes)
    else
      @_current_user = build(:user, attributes)
    end

    if @_current_user.needs_profile?
      unless attributes.include?(:profile_updated_at)
        @_current_user.profile_updated_at = Time.now
      end
    end

    @_current_user.save!

    visit new_user_session_path
    page.should have_content 'Remember me'

    fill_in 'Email', with: @_current_user.email
    fill_in 'Password', with: @_current_user.password
    click_button 'Sign in'
    page.should have_content 'Signed in successfully'

    @_current_user
  end

  def current_user
    @_current_user
  end
end
