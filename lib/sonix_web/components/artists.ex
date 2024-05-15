defmodule SonixWeb.Artists do
  use Phoenix.Component

  import SonixWeb.CoreComponents

  attr :artists, :list, required: true

  def artists(assigns) do
    ~H"""
    <div class="flex flex-wrap pt-4 pb-2">
      <%= for artist <- @artists do %>
        <div
          id={String.replace(artist.name, " ", "")}
          phx-click="toggle_favorite"
          phx-value-artist-name={artist.name}
          class="pr-4 pb-3"
        >
          <div class="flex rounded-lg h-full bg-gray-800 hover:bg-gray-600 p-8 flex-col w-52">
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
