defmodule OneSignal.EmailTest do
  use ExUnit.Case

  describe "email notifications" do
    test "creates notification with all email fields" do
      email_notification =
        OneSignal.Notification.new(%{
          target_channel: :email,
          email_to: ["user1@example.com", "user2@example.com"],
          email_subject: "Welcome to our service!",
          email_body: "<h1>Welcome!</h1><p>Thank you for joining us.</p>",
          email_preheader: "Get started with your account",
          email_from_name: "Your App Team",
          email_from_address: "noreply@yourapp.com",
          email_sender_domain: "mail.yourapp.com",
          email_reply_to_address: "support@yourapp.com",
          include_unsubscribed: false,
          disable_email_click_tracking: false,
          name: "Welcome Email Campaign"
        })

      assert email_notification.target_channel == :email
      assert email_notification.email_to == ["user1@example.com", "user2@example.com"]
      assert email_notification.email_subject == "Welcome to our service!"
      assert email_notification.email_body == "<h1>Welcome!</h1><p>Thank you for joining us.</p>"
      assert email_notification.email_preheader == "Get started with your account"
      assert email_notification.email_from_name == "Your App Team"
      assert email_notification.email_from_address == "noreply@yourapp.com"
      assert email_notification.email_sender_domain == "mail.yourapp.com"
      assert email_notification.email_reply_to_address == "support@yourapp.com"
      assert email_notification.include_unsubscribed == false
      assert email_notification.disable_email_click_tracking == false
      assert email_notification.name == "Welcome Email Campaign"
    end

    test "creates notification with template_id instead of email_body" do
      template_email =
        OneSignal.Notification.new(%{
          target_channel: :email,
          email_to: ["user@example.com"],
          email_subject: "Newsletter",
          template_id: "e59b3a5e-ccc4-44ff-b39e-aa4c668fe6c1",
          email_from_name: "Newsletter Team"
        })

      assert template_email.target_channel == :email
      assert template_email.template_id == "e59b3a5e-ccc4-44ff-b39e-aa4c668fe6c1"
      assert template_email.email_body == nil
    end

    test "creates notification for transactional email with include_unsubscribed" do
      transactional_email =
        OneSignal.Notification.new(%{
          target_channel: :email,
          email_to: ["customer@example.com"],
          email_subject: "Order Confirmation #12345",
          email_body: "<p>Your order has been confirmed.</p>",
          include_unsubscribed: true,
          disable_email_click_tracking: true
        })

      assert transactional_email.include_unsubscribed == true
      assert transactional_email.disable_email_click_tracking == true
    end

    test "creates notification using email tokens for targeting" do
      token_email =
        OneSignal.Notification.new(%{
          target_channel: :email,
          include_email_tokens: ["token1", "token2", "token3"],
          email_subject: "System Update",
          email_body: "<p>System will be updated tonight.</p>"
        })

      assert token_email.include_email_tokens == ["token1", "token2", "token3"]
      assert token_email.email_to == nil
    end

    test "creates notification using segments for email targeting" do
      segment_email =
        OneSignal.Notification.new(%{
          target_channel: :email,
          included_segments: ["Active Users", "Premium Users"],
          excluded_segments: ["Unengaged Users"],
          email_subject: "Special Offer",
          email_body: "<p>Check out our special offer!</p>"
        })

      assert segment_email.included_segments == ["Active Users", "Premium Users"]
      assert segment_email.excluded_segments == ["Unengaged Users"]
    end

    test "creates notification using aliases for email targeting" do
      alias_email =
        OneSignal.Notification.new(%{
          target_channel: :email,
          include_aliases: %{
            external_id: ["user123", "user456"],
            onesignal_id: ["os_id_1", "os_id_2"]
          },
          email_subject: "Personal Message",
          email_body: "<p>This is a personalized message.</p>"
        })

      assert alias_email.include_aliases.external_id == ["user123", "user456"]
      assert alias_email.include_aliases.onesignal_id == ["os_id_1", "os_id_2"]
    end

    test "minimum viable email notification" do
      minimal_email =
        OneSignal.Notification.new(%{
          target_channel: :email
        })

      assert minimal_email.target_channel == :email
      # All other fields should be nil by default
      assert minimal_email.email_to == nil
      assert minimal_email.email_subject == nil
      assert minimal_email.email_body == nil
    end
  end

  describe "email field validation" do
    test "supports all documented OneSignal email fields" do
      # This test ensures we support all the email fields documented in OneSignal API
      supported_fields = [
        # Direct email targeting
        :email_to,
        # Email subject line
        :email_subject,
        # Email body content
        :email_body,
        # Email preheader text
        :email_preheader,
        # Sender display name
        :email_from_name,
        # Sender email address
        :email_from_address,
        # Sending domain
        :email_sender_domain,
        # Reply-to address
        :email_reply_to_address,
        # Send to unsubscribed users
        :include_unsubscribed,
        # Disable click tracking
        :disable_email_click_tracking,
        # Use predefined template
        :template_id,
        # Target by email tokens
        :include_email_tokens,
        # Must be :email
        :target_channel
      ]

      notification_struct_fields = OneSignal.Notification.__struct__() |> Map.keys()

      for field <- supported_fields do
        assert field in notification_struct_fields, "Missing email field: #{field}"
      end
    end
  end
end
