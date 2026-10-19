defmodule DNSTest do
  use ExUnit.Case

  describe "resolve" do
    test "defaults DNS servers" do
      {:ok, results} = DNS.resolve("www.google.com")

      assert is_list(results)
      assert length(results) > 0
    end

    test "can query custom DNS servers" do
      {:ok, results} = DNS.resolve("www.google.com", :a, nameservers: [{"8.8.4.4", 53}])

      assert is_list(results)
      assert length(results) > 0
    end

    test "responds with error if domain not found" do
      assert {:error, _} = DNS.resolve(~c"uifqourefhoqeirhfqeurfhqehfqoerfiuqe.com")
    end

    test "can query DNS servers via tcp" do
      {:ok, results} = DNS.resolve("www.google.com", :a, usevc: true)

      assert is_list(results)
      assert length(results) > 0
    end

    test "resolves :dnskey records" do
      {:ok, results} = DNS.resolve("cloudflare.com", :dnskey, nameservers: [{"1.1.1.1", 53}])

      assert is_list(results)
      assert length(results) > 0

      # DNSKEY RDATA is a binary of flags/protocol/algorithm/public_key.
      assert Enum.all?(results, &is_binary/1)
    end
  end

  describe "encode_type" do
    test "translates DNSSEC and related atoms to their RFC type numbers" do
      assert DNS.encode_type(:sshfp) == 44
      assert DNS.encode_type(:ds) == 43
      assert DNS.encode_type(:rrsig) == 46
      assert DNS.encode_type(:nsec) == 47
      assert DNS.encode_type(:dnskey) == 48
      assert DNS.encode_type(:nsec3) == 50
      assert DNS.encode_type(:nsec3param) == 51
      assert DNS.encode_type(:tlsa) == 52
      assert DNS.encode_type(:cds) == 59
      assert DNS.encode_type(:cdnskey) == 60
      assert DNS.encode_type(:svcb) == 64
      assert DNS.encode_type(:https) == 65
    end

    test "passes other atoms and integers through unchanged" do
      assert DNS.encode_type(:a) == :a
      assert DNS.encode_type(:aaaa) == :aaaa
      assert DNS.encode_type(48) == 48
      assert DNS.encode_type(257) == 257
    end
  end

  describe "query" do
    # test "builds a DNS Record" do
    #   assert %DNS.Record{
    #            anlist: [%DNS.Resource{}],
    #            arlist: [],
    #            header: %DNS.Header{},
    #            nslist: [],
    #            qdlist: [%DNS.Query{}]
    #          } = DNS.query('tungdao.com')
    # end

    # test "queries different record types" do
    #   assert %DNS.Record{
    #            anlist: [%DNS.Resource{}],
    #            arlist: [],
    #            header: %DNS.Header{},
    #            nslist: [],
    #            qdlist: [%DNS.Query{}]
    #          } = DNS.query('tungdao.com', :txt)
    # end
  end
end
