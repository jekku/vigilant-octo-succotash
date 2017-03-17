defmodule Hackathon.DataChannel do
  use Phoenix.Channel

  def join("data:records", _message, socket) do
    {:ok, socket}
  end

  def handle_in("request_points", %{"payload" => payload}, socket) do
    request_accident_data(payload |> Poison.encode, socket)
    {:noreply, socket}
  end

  def handle_out("respond_points", payload, socket) do
    push socket, "respond_points", payload
    {:noreply, socket}
  end

  defp request_accident_data({:ok, geojson} = payload, socket) do
    response =
      HTTPotion.get(
        "https://roadsafety.gov.ph/api/records",
        follow_redirects: true,
        headers: [
          Authorization: "Token 2b341265160309ce130c790176be8b99658eff15"
        ],
        query: %{
          limit: 100,
          polygon: geojson
        }
      )
      |> Map.get(:body)
      |> Poison.decode

    {:ok, %{"count" => count, "next" => next, "results" => results}} = response

    broadcast! socket, "respond_points", %{:results => results}
    request_accident_data(next, socket)
  end

  defp request_accident_data(url, socket) do
    response =
      HTTPotion.get(
        url,
        follow_redirects: true,
        headers: [
          Authorization: "Token 2b341265160309ce130c790176be8b99658eff15"
        ],
      )
      |> Map.get(:body)
      |> Poison.decode

    {:ok, %{"count" => count, "next" => next, "results" => results}} = response

    broadcast! socket, "respond_points", %{:results => results}

    if next != nil do
      request_accident_data(next, socket)
    end
  end

end
