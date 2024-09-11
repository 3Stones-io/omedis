defmodule OmedisWeb.ErrorJSONTest do
  use OmedisWeb.ConnCase, async: true

  test "renders 404" do
    assert OmedisWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert OmedisWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
