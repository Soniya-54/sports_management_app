# EmailJS Setup Guide (No Credit Card Required!)

## Step 1: Create EmailJS Account (100% FREE)

1. Go to: https://www.emailjs.com/
2. Click **"Sign Up"** (top right)
3. Sign up with Google or email
4. **No credit card required!**

**Free Plan Includes:**
- 200 emails/month
- Perfect for your app

## Step 2: Add Email Service

1. After login, go to **"Email Services"** in the dashboard
2. Click **"Add New Service"**
3. Choose **"Gmail"** (recommended if you have Gmail)
   - Or choose any other service (Yahoo, Outlook, etc.)
4. Click **"Connect Account"**
5. Sign in with your Gmail account
6. Give it a name like "Sports App Notifications"
7. Click **"Create Service"**
8. **COPY the Service ID** (looks like: `service_abc123`)

## Step 3: Create Email Template

1. Go to **"Email Templates"** in the dashboard
2. Click **"Create New Template"**
3. **Template Settings:**
   - Template Name: `Booking Notification`

4. **Email Template Content:**

**Subject:**
```
{{subject}}
```

**Content (HTML):**
```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px; }
        .header { padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }
        .confirmed { background: #4CAF50; color: white; }
        .rejected { background: #f44336; color: white; }
        .content { padding: 30px 20px; }
        .details { background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .footer { text-align: center; padding: 20px; color: #999; font-size: 12px; border-top: 1px solid #eee; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header {{#if (eq status 'CONFIRMED')}}confirmed{{else}}rejected{{/if}}">
            <h1>{{#if (eq status 'CONFIRMED')}}✓ Booking Confirmed!{{else}}Booking Update{{/if}}</h1>
        </div>
        <div class="content">
            <p>Hello {{to_name}},</p>
            <p>{{message}}</p>
            
            <div class="details">
                <h3>Booking Details:</h3>
                <p><strong>Venue:</strong> {{venue_name}}</p>
                <p><strong>Date:</strong> {{booking_date}}</p>
                <p><strong>Time Slot:</strong> {{time_slot}}</p>
                <p><strong>Amount:</strong> {{total_price}}</p>
            </div>
            
            <p style="color: #666;">
                {{#if (eq status 'CONFIRMED')}}
                Please arrive 10 minutes before your scheduled time.
                {{else}}
                You can try booking a different time or date through the app.
                {{/if}}
            </p>
        </div>
        <div class="footer">
            <p>Sports Management App</p>
            <p>This is an automated email. Please do not reply.</p>
        </div>
    </div>
</body>
</html>
```

5. **Template Parameters (scroll down):**
   Add these parameters:
   - `to_email`
   - `to_name`
   - `subject`
   - `venue_name`
   - `booking_date`
   - `time_slot`
   - `total_price`
   - `status`
   - `message`

6. Click **"Save"**
7. **COPY the Template ID** (looks like: `template_xyz789`)

## Step 4: Get Your Public Key

1. Go to **"Account"** → **"General"** in the dashboard
2. Find **"Public Key"** section
3. **COPY your Public Key** (looks like: `ABcdEFgh123456789`)

## Step 5: Update Flutter App

Open: `lib/services/email_service.dart`

Replace these values:
```dart
static const String _serviceId = 'YOUR_SERVICE_ID';      // From Step 2
static const String _templateId = 'YOUR_TEMPLATE_ID';    // From Step 3
static const String _publicKey = 'YOUR_PUBLIC_KEY';      // From Step 4
```

**Example:**
```dart
static const String _serviceId = 'service_abc123';
static const String _templateId = 'template_xyz789';
static const String _publicKey = 'ABcdEFgh123456789';
```

## Step 6: Install Dependencies

```powershell
flutter pub get
```

## Step 7: Update pending_bookings_screen.dart

I'll add the email sending code automatically in the next step.

## Step 8: Test

1. Run your app
2. As a player, make a booking and complete payment
3. As a manager, go to pending bookings and confirm/reject
4. **Check the player's email inbox!**

## Troubleshooting

### Email not arriving?
- Check spam folder
- Verify template is saved correctly
- Check EmailJS dashboard → Logs section
- Make sure Service ID, Template ID, and Public Key are correct

### "User doesn't exist" error?
- Go to EmailJS → Email Services
- Make sure your Gmail is connected properly
- Try reconnecting your email account

## Cost

**100% FREE**
- 200 emails/month
- No credit card
- No surprises

---

**Ready?** Start with Step 1 above! 🚀
