# Quick Start: EmailJS Setup (5 Minutes!)

## ✅ What You'll Get
- Email notifications when bookings are confirmed/rejected
- **100% FREE** (200 emails/month)
- **NO CREDIT CARD** required
- Works immediately

---

## Step 1: Create EmailJS Account (2 min)

1. Go to: **https://www.emailjs.com/**
2. Click **"Sign Up"** → Use Google/Email
3. No credit card needed ✓

---

## Step 2: Connect Your Gmail (1 min)

1. In EmailJS dashboard → **"Email Services"**
2. Click **"Add New Service"**
3. Choose **"Gmail"**
4. Click **"Connect Account"** → Sign in with Gmail
5. Copy your **Service ID** (e.g., `service_abc123`)

---

## Step 3: Create Email Template (2 min)

1. Go to **"Email Templates"**
2. Click **"Create New Template"**
3. **Subject line:** Type `{{subject}}`
4. **Content:** Copy-paste this:

```html
<h1>{{#if (eq status 'CONFIRMED')}}✓ Booking Confirmed!{{else}}Booking Update{{/if}}</h1>
<p>Hello {{to_name}},</p>
<p>{{message}}</p>

<div style="background:#f5f5f5; padding:20px; border-radius:8px;">
  <h3>Booking Details:</h3>
  <p><strong>Venue:</strong> {{venue_name}}</p>
  <p><strong>Date:</strong> {{booking_date}}</p>
  <p><strong>Time:</strong> {{time_slot}}</p>
  <p><strong>Amount:</strong> {{total_price}}</p>
</div>

<p>Sports Management App</p>
```

5. Click **"Save"**
6. Copy your **Template ID** (e.g., `template_xyz789`)

---

## Step 4: Get Public Key (30 sec)

1. Go to **"Account"** → **"General"**
2. Copy your **Public Key** (e.g., `ABcdEF123456`)

---

## Step 5: Update Your App (1 min)

Open: `lib/services/email_service.dart`

Replace these 3 lines:
```dart
static const String _serviceId = 'service_abc123';      // From Step 2
static const String _templateId = 'template_xyz789';    // From Step 3
static const String _publicKey = 'ABcdEF123456';        // From Step 4
```

---

## Step 6: Test! 🎉

```powershell
flutter run -d 53051XEKB1P3EC
```

1. Make a booking as player
2. Confirm it as manager
3. **Check your email!** 📧

---

## Troubleshooting

**Email not arriving?**
- Check spam folder
- Verify Step 2: Gmail is connected
- Check EmailJS dashboard → Logs

**"Template not found" error?**
- Verify Template ID is correct
- Make sure template is saved

---

## Cost: $0 Forever ✓

That's it! Now your users get automatic emails! 🚀
