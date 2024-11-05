defmodule OmedisWeb.LogCategoryLive.ShowTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    {:ok, owner} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: owner.id})
    {:ok, group} = create_group(%{organisation_id: organisation.id})
    {:ok, project} = create_project(%{organisation_id: organisation.id})
    {:ok, authorized_user} = create_user()

    {:ok, _} = create_group_user(%{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "LogCategory",
        organisation_id: organisation.id,
        write: true
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Group",
        organisation_id: organisation.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Project",
        organisation_id: organisation.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Organisation",
        organisation_id: organisation.id
      })

    {:ok, log_category} =
      create_log_category(%{
        group_id: group.id,
        project_id: project.id,
        name: "Test Category"
      })

    {:ok, user} = create_user()
    {:ok, group2} = create_group(%{organisation_id: organisation.id})
    {:ok, _} = create_group_user(%{group_id: group2.id, user_id: user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group2.id,
        read: true,
        resource_name: "Group",
        organisation_id: organisation.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group2.id,
        read: true,
        resource_name: "Project",
        organisation_id: organisation.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group2.id,
        read: true,
        resource_name: "Organisation",
        organisation_id: organisation.id
      })

    %{
      authorized_user: authorized_user,
      group: group,
      group2: group2,
      log_category: log_category,
      owner: owner,
      project: project,
      tenant: organisation,
      user: user
    }
  end

  describe "/organisations/:slug/groups/:group_slug/log_categories/:id" do
    test "shows log category details if user is organisation owner", %{
      conn: conn,
      group: group,
      log_category: log_category,
      tenant: organisation,
      owner: owner
    } do
      {:ok, _show_live, html} =
        conn
        |> log_in_user(owner)
        |> live(
          ~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories/#{log_category.id}"
        )

      assert html =~ log_category.name
      assert html =~ "Edit log_category"
    end

    test "shows log category details if user is authorized", %{
      conn: conn,
      group: group,
      log_category: log_category,
      tenant: organisation,
      authorized_user: authorized_user
    } do
      {:ok, _show_live, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(
          ~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories/#{log_category.id}"
        )

      assert html =~ log_category.name
      assert html =~ "Edit log_category"
    end

    test "unauthorized user cannot see log category details", %{
      conn: conn,
      group: group,
      log_category: log_category,
      tenant: organisation,
      user: user
    } do
      assert_raise Ash.Error.Query.NotFound, fn ->
        conn
        |> log_in_user(user)
        |> live(
          ~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories/#{log_category.id}"
        )
      end
    end
  end

  describe "/organisations/:slug/groups/:group_slug/log_categories/:id/show/edit" do
    test "organisation owner can edit log category", %{
      conn: conn,
      group: group,
      log_category: log_category,
      tenant: organisation,
      owner: owner
    } do
      {:ok, show_live, html} =
        conn
        |> log_in_user(owner)
        |> live(
          ~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories/#{log_category.id}/show/edit"
        )

      assert html =~ "Edit log_category"

      assert html =
               show_live
               |> form("#log_category-form",
                 log_category: %{
                   name: "Updated Category",
                   color_code: "#00FF00"
                 }
               )
               |> render_submit()

      assert_patch(
        show_live,
        ~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories/#{log_category.id}"
      )

      assert html =~ "Log category saved successfully"
      assert html =~ "Updated Category"
    end

    test "authorized user can edit log category", %{
      conn: conn,
      group: group,
      log_category: log_category,
      tenant: organisation,
      authorized_user: authorized_user
    } do
      {:ok, show_live, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(
          ~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories/#{log_category.id}/show/edit"
        )

      assert html =~ "Edit log_category"

      assert html =
               show_live
               |> form("#log_category-form", log_category: %{name: "Updated Category"})
               |> render_submit()

      assert_patch(
        show_live,
        ~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories/#{log_category.id}"
      )

      assert html =~ "Log category saved successfully"
      assert html =~ "Updated Category"
    end

    test "unauthorized user cannot edit log category", %{
      conn: conn,
      group: group,
      group2: group2,
      log_category: log_category,
      tenant: organisation,
      user: user
    } do
      {:ok, _} =
        create_access_right(%{
          group_id: group2.id,
          read: true,
          resource_name: "LogCategory",
          organisation_id: organisation.id,
          update: false,
          write: false
        })

      {:error, {:live_redirect, %{flash: flash, to: to}}} =
        conn
        |> log_in_user(user)
        |> live(
          ~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories/#{log_category.id}/show/edit"
        )

      assert to ==
               ~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories/#{log_category.id}"

      assert flash["error"] == "You are not authorized to access this page"
    end

    test "shows validation errors on edit", %{
      conn: conn,
      group: group,
      log_category: log_category,
      tenant: organisation,
      authorized_user: authorized_user
    } do
      {:ok, form_live, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(
          ~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories/#{log_category.id}/show/edit"
        )

      assert html =
               form_live
               |> form("#log_category-form", log_category: %{name: "", color_code: "invalid"})
               |> render_change()

      assert html =~ "must be present"
      assert html =~ "Color code must be a valid hex color code"
    end
  end
end
