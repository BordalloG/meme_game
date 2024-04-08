defmodule MemeGameWeb.PageHTML do
  use MemeGameWeb, :html

  embed_templates "page_html/*"

  def top_wave(assigns) do
    ~H"""
    <div class="bg-bottom bg-top_wave bg-cover bg-no-repeat w-full h-2/6"></div>
    """
  end

  def bottom_wave(assigns) do
    ~H"""
    <div class="bg-top bg-bottom_wave bg-cover bg-no-repeat w-full h-2/6"></div>
    """
  end
end
