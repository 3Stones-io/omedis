defmodule OmedisWeb.LanguageSwitcherLive do
  use OmedisWeb, :live_view

  @impl true
  def mount(_, %{"language" => language} = _session, socket) do
    socket =
      socket
      |> assign(language: language)

    {:ok, socket}
  end

  @impl true
  def handle_event("switch_language", %{"language" => language}, socket) do
    {:noreply,
     socket
     |> redirect(to: "/language-switcher?locale=#{language}")
     |> put_flash(
       :info,
       with_locale(socket.assigns.language, fn -> gettext("Language switched successfully") end)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white  text-gray-900 ">
      <div class="w-[90%] flex flex-col md:text-xl gap-1 justify-center items-start m-auto  pt-4">
        <p>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Please select your preferred language") %>
          <% end) %>
        </p>
        <div
          phx-click="switch_language"
          phx-value-language="de"
          id="switch-language-de"
          class={"flex gap-4 cursor-pointer  #{if @language == "de" do "underline-offset-8 underline  decoration-black " end}"}
        >
          🇩🇪  Deutsch
        </div>
        <div
          phx-click="switch_language"
          phx-value-language="en"
          id="switch-language-en"
          class={"flex gap-4 cursor-pointer  #{if @language == "en" do "underline-offset-8   underline  decoration-black " end}"}
        >
          🇺🇸 English
        </div>

        <div
          phx-click="switch_language"
          phx-value-language="fr"
          id="switch-language-fr"
          class={"flex gap-4 cursor-pointer  #{if @language == "fr" do "underline-offset-8   underline  decoration-black " end}"}
        >
          🇫🇷 French
        </div>

        <div
          phx-click="switch_language"
          phx-value-language="it"
          id="switch-language-it"
          class={"flex gap-4 cursor-pointer  #{if @language == "it" do "underline-offset-8   underline  decoration-black " end}"}
        >
          🇮🇹 Italian
        </div>
      </div>
    </div>
    """
  end
end
