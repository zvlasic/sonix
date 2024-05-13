defmodule SonixWeb.Artists do
  use Phoenix.Component

  import SonixWeb.CoreComponents

  attr :artists, :list, required: true

  def artists(assigns) do
    ~H"""
    <div class="flex flex-wrap justify-center mt-10">
      <%= for artist <- @artists do %>
        <div phx-click="toggle_favorite" phx-value-artist-name={artist.name} class="p-4 max-w-sm">
          <div class="flex rounded-lg h-full bg-gray-800 p-8 flex-col" class="bg-emerald-300">
            <div class="flex items-center mb-3">
              <h2 class="text-white dark:text-white text-lg font-medium"><%= artist.name %></h2>
              <.icon :if={artist.favorite} name="hero-check" class="bg-green-300" />
              <.icon :if={not artist.favorite} name="hero-x-mark" class="bg-red-300" />
            </div>
            <div class="flex flex-col justify-between flex-grow">
              <p class="leading-relaxed text-base text-white dark:text-gray-300">
                Playcount: <%= artist.playcount %>
              </p>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
