defmodule Hackathon.CentroidHelper do
  def find_centroid(points) do
    weighted_x = Enum.reduce(points, 0, fn (
      %{:x => x1, :severity => severity},
      acc
    ) ->
      (x1 * severity) + acc
    end)

    weighted_y = Enum.reduce(points, 0, fn (
      %{:y => y1, :severity => severity},
      acc
    ) ->
      (y1 * severity) + acc
    end)

    denominator_weights = Enum.reduce(points, 0, fn(
      %{:severity => severity},
      acc
    ) ->
      severity + acc
    end)

    %{
      :x => weighted_x / denominator_weights,
      :y => weighted_y / denominator_weights
    }
  end
end
