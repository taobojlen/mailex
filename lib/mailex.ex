defmodule Mailex do
  @moduledoc """
  RFC 5322 email message parser.
  """

  defdelegate parse(raw), to: Mailex.Parser
  defdelegate parse!(raw), to: Mailex.Parser
end
