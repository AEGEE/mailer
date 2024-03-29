defmodule OmsmailerWeb.PageControllerTest do
  use OmsmailerWeb.ConnCase
  use Bamboo.Test

  @confirm_email_params %{name: "test", surname: "user", token: "abcdef123456789"}


  # A get just returns success:true, kind of a status check
  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert json_response(conn, 200)
  end

  # test "GET /healthcheck", %{conn: conn} do
  #   conn = get conn, "/healthcheck"
  #   assert json_response(conn, 200)
  # end

  # Tests test template
  test "POST / default template", %{conn: conn} do
    conn = post conn, "/", %{template: "index.html", parameters: %{heading: "pirates!"}, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Signup link works
  test "POST / confirm_email", %{conn: conn} do
    conn = post conn, "/", %{template: "confirm_email.html", parameters: @confirm_email_params, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Test headers
  test "POST / confirm_email requires parameters", %{conn: conn} do
    conn = post conn, "/", %{template: "confirm_email.html", parameters: %{}, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 422)
    assert_no_emails_delivered()
  end
  test "POST / confirm_email requires to address", %{conn: conn} do
    conn = post conn, "/", %{template: "confirm_email.html", parameters: @confirm_email_params, to: "", subject: "pirates"}
    assert json_response(conn, 422)
    assert_no_emails_delivered()
  end
  test "POST / confirm_email requires subject", %{conn: conn} do
    conn = post conn, "/", %{template: "confirm_email.html", parameters: @confirm_email_params, from: "mailer@aegee.org", to: "test@aegee.org", subject: ""}
    assert json_response(conn, 422)
    assert_no_emails_delivered()
  end

  test "POST / with invalid template renders 404", %{conn: conn} do
    conn = post conn, "/", %{template: "really_long_nonexistent_template.html", parameters: %{}, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 404)
    assert_no_emails_delivered()
  end

  test "POST / confirm_email allows for custom from address", %{conn: conn} do
    conn = post conn, "/", %{template: "confirm_email.html", parameters: @confirm_email_params, to: "test@aegee.org", subject: "pirates", from: "someweird@aegee.org"}
    assert json_response(conn, 200)
    assert_email_delivered_with(from: {nil, "someweird@aegee.org"})
  end

  test "POST / confirm_email allows for cc address", %{conn: conn} do
    conn = post conn, "/", %{template: "confirm_email.html", parameters: @confirm_email_params, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates", cc: "someweird@aegee.org"}
    assert json_response(conn, 200)
    assert_email_delivered_with(cc: [nil: "someweird@aegee.org"])
  end

  test "POST / confirm_email allows for bcc address", %{conn: conn} do
    conn = post conn, "/", %{template: "confirm_email.html", parameters: @confirm_email_params, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates", bcc: "someweird@aegee.org"}
    assert json_response(conn, 200)
    assert_email_delivered_with(bcc: [nil: "someweird@aegee.org"])
  end

  test "POST / confirm_email allows for reply_to address", %{conn: conn} do
    conn = post conn, "/", %{template: "confirm_email.html", parameters: @confirm_email_params, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates", reply_to: "someweird@aegee.org"}
    assert json_response(conn, 200)
    assert_email_delivered_with(headers: %{"Reply-To" => "someweird@aegee.org"})
  end

  # Custom works
  test "POST / custom", %{conn: conn} do
    conn = post conn, "/", %{template: "custom.html", parameters: %{body: "<b>custom html code here</b>"}, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Password reset works
  test "POST / password reset", %{conn: conn} do
    conn = post conn, "/", %{template: "password_reset.html", parameters: %{token: "astdefern1234"}, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Password reset works
  test "POST / mail change", %{conn: conn} do
    conn = post conn, "/", %{template: "mail_change.html", parameters: %{token: "astdefern1234", first_name: "Name"}, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  test "POST / allows for several recipients", %{conn: conn} do
    conn = post conn, "/", %{template: "custom.html", parameters: %{body: "huhu"}, from: "mailer@aegee.org", to: ["test1@aegee.org", "test2@aegee.org", "test3@aegee.org"], subject: "pirates"}
    assert json_response(conn, 200)
    # I have no clue why the nil: thing is necessary...
    assert_email_delivered_with(to: [nil: "test1@aegee.org"])
    assert_email_delivered_with(to: [nil: "test2@aegee.org"])
    assert_email_delivered_with(to: [nil: "test3@aegee.org"])
  end

  test "POST / allows for several recipients with custom template parameters", %{conn: conn} do
    conn = post conn, "/", %{template: "custom.html", parameters: [%{body: "huhu1"}, %{body: "huhu2"}, %{body: "huhu3"}], from: "mailer@aegee.org", to: ["test1@aegee.org", "test2@aegee.org", "test3@aegee.org"], subject: "pirates"}
    assert json_response(conn, 200)
    # I have no clue why the nil: thing is necessary...
    # I also have no clue why the :ok thing is necessary
    assert_email_delivered_with(to: [nil: "test1@aegee.org"], html_body: Phoenix.View.render_to_string(OmsmailerWeb.PageView, "custom.html", parameters: %{"body" => "huhu1"}))
    assert_email_delivered_with(to: [nil: "test2@aegee.org"], html_body: Phoenix.View.render_to_string(OmsmailerWeb.PageView, "custom.html", parameters: %{"body" => "huhu2"}))
    assert_email_delivered_with(to: [nil: "test3@aegee.org"], html_body: Phoenix.View.render_to_string(OmsmailerWeb.PageView, "custom.html", parameters: %{"body" => "huhu3"}))
  end

  test "POST / autocompletes template file", %{conn: conn} do
    conn = post conn, "/", %{template: "custom", parameters: %{body: "huhu"}, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # New member works
  test "POST / new_member", %{conn: conn} do
    conn = post conn, "/", %{template: "new_member.html", parameters: %{name: "Franz", surname: "Ferdinant"}, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Membership expired
  test "POST / membership expired", %{conn: conn} do
    conn = post conn, "/", %{template: "membership_expired.html", parameters: %{body: "AEGEE-Dresden", last_payment: "2018-11-23T08:51:04.038159"}, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Statutory applied
  test "POST / statutory applied should work with questions and answers", %{conn: conn} do
    question = %{"description" => "Phone number:", "required" => false, "type" => "string"}
    conn = post conn, "/", %{template: "statutory_applied.html", parameters: %{event: %{name: "test", questions: [question] }, application: %{answers: ["test"] } }, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Statutory edited
  test "POST / statutory edited should work with questions and answers", %{conn: conn} do
    question = %{"description" => "Phone number:", "required" => false, "type" => "string"}
    conn = post conn, "/", %{template: "statutory_edited.html", parameters: %{event: %{name: "test", questions: [question] }, application: %{answers: ["test"] } }, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Board statutory applied
  test "POST / statutory board applied should work with questions and answers", %{conn: conn} do
    question = %{"description" => "Phone number:", "required" => false, "type" => "string"}
    event = %{"name" =>  "test", "questions" => [question] }
    application = %{answers: ["test"] }

    conn = post conn, "/", %{template: "statutory_board_applied.html", parameters: %{ event: event, application: application }, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Board statutory edited
  test "POST / statutory board edited should work with questions and answers", %{conn: conn} do
    question = %{"description" => "Phone number:", "required" => false, "type" => "string"}
    event = %{"name" =>  "test", "questions" => [question] }
    application = %{answers: ["test"] }

    conn = post conn, "/", %{template: "statutory_board_edited.html", parameters: %{ event: event, application: application }, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Member joined
  test "POST / member joined", %{conn: conn} do
    conn = post conn, "/", %{template: "member_joined.html", parameters: %{body_name: "AEGEE-Dresden", body_id: 1, member_firstname: "Test", member_lastname: "Member"}, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Events status changed
  test "POST / event status changed should work", %{conn: conn} do
    conn = post conn, "/", %{template: "events_status_changed.html", parameters: %{
      event: %{name: "test", status: "draft" },
      old_status: "published"
    }, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}

    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end


  # Events applied
  test "POST / events applied should work with questions and answers", %{conn: conn} do
    question = %{"description" => "Phone number:", "required" => false, "type" => "string"}
    conn = post conn, "/", %{template: "events_applied.html", parameters: %{event: %{name: "test", questions: [question] }, application: %{answers: ["test"] } }, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Events edited
  test "POST / events edited should work with questions and answers", %{conn: conn} do
    question = %{"description" => "Phone number:", "required" => false, "type" => "string"}
    conn = post conn, "/", %{template: "events_edited.html", parameters: %{event: %{name: "test", questions: [question] }, application: %{answers: ["test"] } }, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Events created
  test "POST / events event created should work", %{conn: conn} do
    conn = post conn, "/", %{template: "events_event_created.html", parameters: %{event: %{name: "test", url: "test" } }, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Events edited
  test "POST / events event updated should work", %{conn: conn} do
    conn = post conn, "/", %{template: "events_event_updated.html", parameters: %{event: %{name: "test", url: "test" } }, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Event submitted
  test "POST / event submitted should work", %{conn: conn} do
    conn = post conn, "/", %{template: "events_submitted.html", parameters: %{event: %{name: "test", url: "test" } }, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Candidature submitted
  test "POST / candidature submitted should work", %{conn: conn} do
    conn = post conn, "/", %{template: "candidate_applied.html", parameters: %{position: %{name: "test", event_id: "1"}, candidate: %{first_name: "test", last_name: "test"} }, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Summer University event status changed
  test "POST / summeruniversity event status changed should work", %{conn: conn} do
    conn = post conn, "/", %{template: "summeruniversity_status_changed.html", parameters: %{
      event: %{name: "test", status: "first draft" },
      old_status: "first approval"
    }, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}

    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Summer University event created
  test "POST / summeruniversity event created should work", %{conn: conn} do
    conn = post conn, "/", %{template: "summeruniversity_event_created.html", parameters: %{event: %{name: "test", url: "test" } }, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Summer University event edited
  test "POST / summeruniversity event updated should work", %{conn: conn} do
    conn = post conn, "/", %{template: "summeruniversity_event_updated.html", parameters: %{event: %{name: "test", url: "test" } }, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end

  # Summer University event submitted
  test "POST / summeruniversity event submitted should work", %{conn: conn} do
    conn = post conn, "/", %{template: "summeruniversity_submitted.html", parameters: %{event: %{name: "test", url: "test" } }, from: "mailer@aegee.org", to: "test@aegee.org", subject: "pirates"}
    assert json_response(conn, 200)
    assert_email_delivered_with(subject: "pirates")
  end
end
