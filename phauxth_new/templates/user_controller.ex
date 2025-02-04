defmodule <%= base %>Web.UserController do
  use <%= base %>Web, :controller

  import <%= base %>Web.Authorize

  alias Phauxth.Log<%= if api do %>
  alias <%= base %>.Accounts<% else %>
  alias <%= base %>.{Accounts, Accounts.User}<% end %><%= if confirm do %>
  alias <%= base %>Web.{Auth.Token, Email}<% end %><%= if api do %>

  action_fallback <%= base %>Web.FallbackController<% end %>

  # the following plugs are defined in the controllers/authorize.ex file
  plug :user_check when action in [:index, :show]<%= if api do %>
  plug :id_check when action in [:update, :delete]<% else %>
  plug :id_check when action in [:edit, :update, :delete]<% end %>

  def index(conn, _) do
    users = Accounts.list_users()<%= if api do %>
    render(conn, "index.json", users: users)<% else %>
    render(conn, "index.html", users: users)<% end %>
  end<%= if not api do %>

  def new(conn, _) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end<% end %><%= if confirm do %>

  def create(conn, %{"user" => %{"email" => email} = user_params}) do
    key = Token.sign(%{"email" => email})<% else %>

  def create(conn, %{"user" => user_params}) do<% end %><%= if api do %>
    with {:ok, user} <- Accounts.create_user(user_params) do
      Log.info(%Log{user: user.id, message: "user created"})<%= if confirm do %>
      Email.confirm_request(email, key)<% end %>
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.user_path(conn, :show, user))
      |> render("show.json", user: user)<% else %>
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        Log.info(%Log{user: user.id, message: "user created"})
<%= if confirm do %>
        Email.confirm_request(email, key)
<% end %>

        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: Routes.session_path(conn, :new))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)<% end %>
    end
  end

  def show(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"id" => id}) do
    user = if id == to_string(user.id), do: user, else: Accounts.get_user(id)<%= if api do %>
    render(conn, "show.json", user: user)<% else %>
    render(conn, "show.html", user: user)<% end %>
  end<%= if not api do %>

  def edit(%Plug.Conn{assigns: %{current_user: user}} = conn, _) do
    changeset = Accounts.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end<% end %>

  def update(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"user" => user_params}) do<%= if api do %>
    with {:ok, user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: user)<% else %>
    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)<% end %>
    end
  end

  def delete(%Plug.Conn{assigns: %{current_user: user}} = conn, _) do
    {:ok, _user} = Accounts.delete_user(user)<%= if api do %>
    send_resp(conn, :no_content, "")<% else %>

    conn
    |> delete_session(:phauxth_session_id)
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: Routes.session_path(conn, :new))<% end %>
  end
end
