# Email Notification Setup Guide

This guide will help you set up email notifications for booking confirmations and rejections.

## Prerequisites
- Firebase project set up (✓ Already done)
- Firebase Blaze (pay-as-you-go) plan for Cloud Functions
- SendGrid account (free tier available)

## Step 1: Upgrade Firebase to Blaze Plan

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **sports-management-app-bf547**
3. Click on **"Upgrade"** in the left sidebar or top banner
4. Choose **"Blaze (pay-as-you-go)"** plan
5. Add payment method (free tier includes 2M function invocations/month)

**Don't worry about costs:** You get generous free limits:
- 2,000,000 function invocations/month (FREE)
- 400,000 GB-seconds/month (FREE)
- 200,000 CPU-seconds/month (FREE)
- For small apps like yours, it will remain FREE

## Step 2: Create SendGrid Account

1. Go to [SendGrid.com](https://sendgrid.com)
2. Click **"Sign Up"** (or **"Start for Free"**)
3. Fill in your details
4. Verify your email address

**SendGrid Free Tier:**
- 100 emails/day (FREE forever)
- Perfect for your app

## Step 3: Get SendGrid API Key

1. Log into SendGrid dashboard
2. Go to **Settings** → **API Keys**
3. Click **"Create API Key"**
4. Name: `Sports Management App`
5. Select **"Full Access"** or **"Restricted Access"** (with Mail Send permission)
6. Click **"Create & View"**
7. **COPY THE API KEY** (you'll only see it once!)
   - Example: `SG.xxxxxxxxxxxxxxxxx.yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy`

## Step 4: Verify Sender Email (SendGrid)

1. In SendGrid dashboard, go to **Settings** → **Sender Authentication**
2. Click **"Verify a Single Sender"**
3. Fill in the form:
   - From Name: `Sports Management App`
   - From Email: Your email (e.g., `yourname@gmail.com`)
   - Reply To: Same email
   - Company details (can be anything for testing)
4. Click **"Create"**
5. Check your email and verify the sender

## Step 5: Configure Firebase Environment Variables

Run these commands in your terminal (replace with your actual values):

```powershell
# Set SendGrid API Key
firebase functions:config:set sendgrid.api_key="YOUR_SENDGRID_API_KEY_HERE"

# Set From Email (the email you verified in SendGrid)
firebase functions:config:set sendgrid.from_email="yourname@gmail.com"
```

**Example:**
```powershell
firebase functions:config:set sendgrid.api_key="SG.abc123xyz789..."
firebase functions:config:set sendgrid.from_email="john@gmail.com"
```

## Step 6: Install Dependencies

```powershell
cd functions
pip install -r requirements.txt
cd ..
```

## Step 7: Deploy Cloud Functions

```powershell
firebase deploy --only functions
```

This will take a few minutes. You'll see:
- ✓ functions[send_booking_notification] Successful create operation.

## Step 8: Test the Notification

1. Open your app on the phone
2. As a player:
   - Book a venue
   - Complete payment
3. As a manager:
   - Go to "Pending Bookings"
   - Confirm or reject the booking
4. **Check the player's email inbox** for the notification!

## Troubleshooting

### Function not deploying?
- Make sure you upgraded to Blaze plan
- Run: `firebase login` to ensure you're logged in
- Check: `firebase projects:list` to see your projects

### Email not arriving?
1. Check SendGrid dashboard → Activity feed
2. Verify sender email is verified
3. Check spam folder
4. Check Firebase Functions logs:
   ```powershell
   firebase functions:log
   ```

### Check if environment variables are set:
```powershell
firebase functions:config:get
```

Should show:
```json
{
  "sendgrid": {
    "api_key": "SG.xxx...",
    "from_email": "your@email.com"
  }
}
```

## Cost Estimate

**For 100 bookings/day:**
- Cloud Functions: FREE (well within 2M/month limit)
- SendGrid: FREE (100 emails/day)
- **Total: $0/month** ✓

## Email Templates

The function automatically sends:

### ✓ Confirmed Booking Email:
- Green header with checkmark
- Booking details (venue, date, time, amount)
- Professional formatting

### ✗ Rejected Booking Email:
- Red header
- Booking details
- Suggestion to contact venue or rebook

## Next Steps

After setup is complete:
1. Test with real bookings
2. Customize email templates in `functions/main.py` if needed
3. Monitor SendGrid dashboard for email delivery stats
4. Check Firebase console for function execution logs

---

**Need Help?**
- SendGrid Docs: https://docs.sendgrid.com
- Firebase Functions: https://firebase.google.com/docs/functions
- Check logs: `firebase functions:log --only send_booking_notification`
