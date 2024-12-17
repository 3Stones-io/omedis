defimpl String.Chars, for: Omedis.Accounts.User do
  def to_string(user) do
    if user.as_string do
      user.as_string
    else
      user.email
    end
  end
end
