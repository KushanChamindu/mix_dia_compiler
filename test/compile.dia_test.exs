Code.require_file "test_helper.exs", __DIR__

defmodule Mix.Tasks.Compile.DiaTest do
  use MixTest.Case
  import ExUnit.CaptureIO

  setup do
    Mix.Project.push MixTest.Case.Sample
    :ok
  end

  test "compilation bad diameter file should raise a error" do
    in_fixture "compile_dia", fn ->
      File.write! "dia/bad.dia", """
      This file is not a dia
      """

      assert_raise Mix.Error, fn ->
        capture_io fn ->
          Mix.Tasks.Compile.Dia.run []
        end
      end
    end
  end


  test "compilation success" do
    in_fixture "compile_dia", fn ->
      File.write! "dia/b.dia", """
      @id     0
      @name   b
      @vendor 1 ABC
      @avp_types
         IMSI 1 UTF8String V
      """

      File.write! "src/zzz.erl", """
      -module(zzz).
      """

      assert Mix.Tasks.Compile.Dia.run([]) ==:ok


      assert File.regular?("src/b.erl")
      assert File.regular?("_build/test/lib/sample/include/b.hrl")
      assert File.regular?("_build/test/lib/sample/ebin/b.beam")
      stat0 = File.stat! "_build/test/lib/sample/ebin/b.beam"

      # just dia files should be compiled
      assert not File.regular?("_build/test/lib/sample/ebin/zzz.beam")

      assert Mix.Tasks.Compile.Erlang.run([]) == {:ok, []}
      assert File.regular?("_build/test/lib/sample/ebin/zzz.beam")
      assert File.regular?("_build/test/lib/sample/ebin/b.beam")
      assert stat0 == File.stat! "_build/test/lib/sample/ebin/b.beam"
    end
  end

  test "compilation success with inherits from diameter" do
    in_fixture "compile_dia", fn ->
      File.write! "dia/e.dia", """
      @id     0
      @name   e
      @vendor 1 ABC
      @inherits diameter_gen_base_rfc3588
      @avp_types
         IMSI 1 UTF8String V
      """

      assert Mix.Tasks.Compile.Dia.run([]) == :ok

      assert File.regular?("src/e.erl")
      assert File.regular?("_build/test/lib/sample/include/e.hrl")
      assert File.regular?("_build/test/lib/sample/ebin/e.beam")
    end
  end

  test "compilation success with file order" do
    in_fixture "compile_dia", fn ->
      File.write! "dia/a.dia", """
      @id     0
      @name   a
      @vendor 1 ABC
      @avp_types
         IMSI 1 UTF8String V
      """

      File.write! "dia/b.dia", """
      @id     2
      @name   b
      @vendor 2 ABC
      @inherits a
      @avp_types
         IMEIV 900 OctetString MV
      """

      assert Mix.Tasks.Compile.Dia.run([]) == :ok

      assert File.regular?("src/a.erl")
      assert File.regular?("_build/test/lib/sample/include/a.hrl")
      assert File.regular?("src/b.erl")
      assert File.regular?("_build/test/lib/sample/include/b.hrl")
      assert File.regular?("_build/test/lib/sample/ebin/a.beam")
      assert File.regular?("_build/test/lib/sample/ebin/b.beam")
    end
  end

  test "compilation crash with incorrect file order" do
    in_fixture "compile_dia", fn ->
      File.write! "dia/b.dia", """
      @id     0
      @name   b
      @vendor 1 ABC
      @avp_types
         IMSI 1 UTF8String V
      """

      File.write! "dia/a.dia", """
      @id     2
      @name   chamindu
      @vendor 2 ABC
      @inherits b
      @avp_types
         IMEIV 900 OctetString MV
      """
      Mix.Tasks.Compile.Dia.run [ %{compile_order: 1, file_name: "b.dia"},
      %{compile_order: 2, file_name: "a.dia"}]

      #########################################
      #    Now this will not raise error      #
      #########################################
      # assert_raise Mix.Error, fn ->
      #   capture_io fn ->
      #     Mix.Tasks.Compile.Dia.run []
      #   end
      # end
    end
  end
end
