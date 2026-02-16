"""
Cloud Functions for Sports Management App
Sends email notifications when bookings are confirmed or rejected
"""

from firebase_functions import firestore_fn, options
from firebase_admin import initialize_app, firestore
import os
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

initialize_app()

# Get SendGrid API key from environment variable
SENDGRID_API_KEY = os.environ.get('SENDGRID_API_KEY')
FROM_EMAIL = os.environ.get('FROM_EMAIL', 'noreply@sportsmanagement.app')

@firestore_fn.on_document_updated(
    document="bookings/{bookingId}",
    max_instances=10
)
def send_booking_notification(event: firestore_fn.Event[firestore_fn.Change]) -> None:
    """
    Triggers when a booking document is updated
    Sends email notification when booking status changes to confirmed or rejected
    """
    
    # Get the new and old data
    new_data = event.data.after.to_dict() if event.data.after else {}
    old_data = event.data.before.to_dict() if event.data.before else {}
    
    # Check if booking status changed
    new_status = new_data.get('bookingStatus')
    old_status = old_data.get('bookingStatus')
    
    # Only send email if status changed to 'confirmed' or 'rejected'
    if new_status == old_status or new_status not in ['confirmed', 'rejected']:
        return
    
    # Get user email
    user_email = new_data.get('userEmail')
    if not user_email:
        print(f"No email found for booking {event.params['bookingId']}")
        return
    
    # Get booking details
    venue_name = new_data.get('venueName', 'N/A')
    booking_date = new_data.get('bookingDate')
    time_slot = new_data.get('timeSlot', 'N/A')
    total_price = new_data.get('totalPrice', 0)
    
    # Format date
    try:
        if booking_date:
            date_str = booking_date.strftime('%B %d, %Y')
        else:
            date_str = 'N/A'
    except:
        date_str = 'N/A'
    
    # Prepare email content based on status
    if new_status == 'confirmed':
        subject = f'Booking Confirmed - {venue_name}'
        html_content = f"""
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
                <div style="background: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 10px 10px 0 0;">
                    <h1 style="margin: 0;">✓ Booking Confirmed!</h1>
                </div>
                <div style="padding: 30px 20px;">
                    <p style="font-size: 16px;">Great news! Your booking has been confirmed by the venue manager.</p>
                    
                    <div style="background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
                        <h3 style="color: #4CAF50; margin-top: 0;">Booking Details:</h3>
                        <p><strong>Venue:</strong> {venue_name}</p>
                        <p><strong>Date:</strong> {date_str}</p>
                        <p><strong>Time Slot:</strong> {time_slot}</p>
                        <p><strong>Amount Paid:</strong> Rs. {total_price}</p>
                    </div>
                    
                    <p style="color: #666;">Please arrive 10 minutes before your scheduled time.</p>
                    <p style="color: #666;">If you need to make any changes, please contact the venue directly.</p>
                </div>
                <div style="text-align: center; padding: 20px; color: #999; font-size: 12px; border-top: 1px solid #eee;">
                    <p>Sports Management App</p>
                    <p>This is an automated email. Please do not reply.</p>
                </div>
            </div>
        </body>
        </html>
        """
    else:  # rejected
        subject = f'Booking Update - {venue_name}'
        html_content = f"""
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
                <div style="background: #f44336; color: white; padding: 20px; text-align: center; border-radius: 10px 10px 0 0;">
                    <h1 style="margin: 0;">Booking Not Approved</h1>
                </div>
                <div style="padding: 30px 20px;">
                    <p style="font-size: 16px;">We're sorry, but your booking could not be confirmed.</p>
                    
                    <div style="background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
                        <h3 style="color: #f44336; margin-top: 0;">Booking Details:</h3>
                        <p><strong>Venue:</strong> {venue_name}</p>
                        <p><strong>Date:</strong> {date_str}</p>
                        <p><strong>Time Slot:</strong> {time_slot}</p>
                        <p><strong>Amount:</strong> Rs. {total_price}</p>
                    </div>
                    
                    <p style="color: #666;">Please contact the venue manager for more information or to book another time slot.</p>
                    <p style="color: #666;">You can try booking a different time or date through the app.</p>
                </div>
                <div style="text-align: center; padding: 20px; color: #999; font-size: 12px; border-top: 1px solid #eee;">
                    <p>Sports Management App</p>
                    <p>This is an automated email. Please do not reply.</p>
                </div>
            </div>
        </body>
        </html>
        """
    
    # Send email using SendGrid
    try:
        if not SENDGRID_API_KEY:
            print("SendGrid API key not configured")
            return
            
        message = Mail(
            from_email=FROM_EMAIL,
            to_emails=user_email,
            subject=subject,
            html_content=html_content
        )
        
        sg = SendGridAPIClient(SENDGRID_API_KEY)
        response = sg.send(message)
        
        print(f"Email sent to {user_email}: Status {response.status_code}")
        
    except Exception as e:
        print(f"Error sending email: {str(e)}")