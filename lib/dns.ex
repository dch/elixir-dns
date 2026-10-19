defmodule DNS do
  @type nameserver :: {String.t(), port :: 1..65535}
  @type res_option ::
          :inet_res.res_option()
          | {:alt_nameservers, [nameserver()]}
          | {:nameservers, [nameserver()]}
  # :inet_res.rr_type is not exported
  @type resolve_error :: :inet_res.res_error() | :not_found

  @type rr_type ::
          :a
          | :aaaa
          | :caa
          | :cdnskey
          | :cds
          | :cname
          | :dnskey
          | :ds
          | :gid
          | :hinfo
          | :https
          | :mb
          | :md
          | :mf
          | :mg
          | :minfo
          | :mx
          | :naptr
          | :ns
          | :nsec
          | :nsec3
          | :nsec3param
          | :null
          | :ptr
          | :rrsig
          | :soa
          | :spf
          | :srv
          | :sshfp
          | :svcb
          | :tlsa
          | :txt
          | :uid
          | :uinfo
          | :unspec
          | :uri
          | :wks
          # Raw integer RR types unsupported by :inet_res atoms.
          | integer()

  @doc """
  Resolves the answer for a DNS query.

  ## Examples

      iex> DNS.resolve("tungdao.com")
      {:ok, [{1, 1, 1, 1}]}

      iex> DNS.resolve("tungdao.com", :txt)
      {:ok, [['v=spf1 a mx ~all']]}

      iex> DNS.resolve("tungdao.com", :a, nameservers: [{"8.8.4.4", 53}])
      {:ok, [{1, 1, 1, 1}]}

      iex> DNS.resolve("tungdao.com", :a, usevc: true)
      {:ok, [{1, 1, 1, 1}]}

  """
  @spec resolve(String.t(), rr_type(), [res_option()], timeout()) ::
          {:ok, list()} | {:error, resolve_error()}

  def resolve(domain, type \\ :a, opts \\ [], timeout \\ :infinity) do
    case query(domain, type, opts, timeout) do
      {:ok, %DNS.Record{anlist: anlist}} when is_list(anlist) and length(anlist) > 0 ->
        data =
          anlist
          |> Enum.map(& &1.data)
          |> Enum.reject(&is_nil/1)

        {:ok, data}

      {:ok, %DNS.Record{anlist: anlist}} when is_list(anlist) and length(anlist) == 0 ->
        {:error, :not_found}

      error ->
        error
    end
  end

  @doc """
  Queries the DNS server and returns the result.

  ## Examples

  Queries for A records:

      iex> DNS.query("tungdao.com")

  Queries for the MX records:

      iex> DNS.query("tungdao.com", :mx)

  Queries for A records, using OpenDNS:

      iex> DNS.query("tungdao.com", :a, nameservers: [{"8.8.4.4", 53}])


  Queries for A records, using OpenDNS, with TCP:

      iex> DNS.query("tungdao.com", :a, nameservers: [{"8.8.4.4", 53}], usevc: true)

  Returns a standard error tuple on failure, dropping the more complex
  possible return types that the underlying OTP libraries provide.
  """
  @spec query(String.t(), rr_type(), [res_option()], timeout()) ::
          {:ok, DNS.Record.t()} | {:error, :inet_res.res_error()}
  def query(name, type \\ :a, opts \\ [], timeout \\ :infinity) do
    case :inet_res.resolve(
           to_charlist(name),
           :in,
           encode_type(type),
           transform_opts(opts),
           timeout
         ) do
      {:ok, response} ->
        {:ok, DNS.Record.from_record(response)}

      {:error, {reason, _response}} ->
        {:error, reason}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # RFC-defined RR type numbers not exposed by :inet_res (see inet_dns.hrl).
  # Only types listed here are translated; all other atoms/integers pass through.
  @rr_type_numbers %{
    cdnskey: 60,
    cds: 59,
    dnskey: 48,
    ds: 43,
    https: 65,
    nsec: 47,
    nsec3: 50,
    nsec3param: 51,
    rrsig: 46,
    sshfp: 44,
    svcb: 64,
    tlsa: 52
  }

  @doc """
  Maps an atom RR type to the integer value `:inet_res.resolve/5` expects.

  DNSSEC and related RR types listed in `@rr_type_numbers` are translated
  because OTP's `:inet_res` does not expose them as atoms. All other atoms and
  integers are passed through unchanged.
  """
  @spec encode_type(rr_type()) :: atom() | integer()
  def encode_type(type) do
    Map.get(@rr_type_numbers, type, type)
  end

  defp transform_opts(opts) do
    Enum.map(opts, fn {key, value} -> {key, transform_opt(key, value)} end)
  end

  defp transform_opt(key, nameservers)
       when key in [:alt_nameservers, :nameservers] and is_list(nameservers) do
    Enum.map(nameservers, fn {nameserver, port} ->
      case nameserver do
        n when is_tuple(n) ->
          {n, port}

        n when is_binary(n) ->
          {:ok, address} = :inet.parse_address(to_charlist(n))
          {address, port}
      end
    end)
  end

  defp transform_opt(_key, value) do
    value
  end
end
