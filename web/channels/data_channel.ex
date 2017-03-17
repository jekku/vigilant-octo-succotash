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
    necessities =
      payload
      |> Enum.map(fn(data) ->
        %{
          "geom" => %{
            "coordinates" => [x, y]
          },
          "data" => %{
            "IncidentDetails" => severity
          }
        } = data

        %{
          :x => x,
          :y => y,
          :severity => severity
        }
      end)

    push socket, "respond_points", necessities
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
    #broadcast! socket, "respond_points", %{:results => results |> simplify}
    request_accident_data(next, socket, results |> simplify)
  end

  defp request_accident_data(url, socket, prev \\ []) do
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
    current = results |> simplify

    if next != nil do
      request_accident_data(next, socket, prev ++ current)
    else
      broadcast! socket, "respond_points", %{:results => prev ++ current}
      broadcast! socket, "receive_centroid", Hackathon.CentroidHelper.find_centroid(prev ++ current)
    end
  end

  defp simplify(payload) do
    payload |>
    Enum.map(fn(data) ->
      %{
        "geom" => %{
            "coordinates" => [x, y]
        },
        "data" => %{
          "incidentDetails" =>
            %{"Severity" => severity}
        }
      } = data

      %{
        :x => x,
        :y => y,
        :severity => severity |> analyzeSeverity
      }
    end)
  end

  defp analyzeSeverity(severities) do
    cond do
      severities === "Property" -> 0.3
      severities === "Injury" -> 0.5
      severities === "Fatal" -> 1.0
      Enum.member?(severities, "Fatal") -> 1.0
      Enum.member?(severities, "Injury") -> 0.5
      Enum.member?(severities, "Property") -> 0.3
      true -> 0.3
    end
  end

end
