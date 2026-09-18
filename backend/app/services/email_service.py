import smtplib
from email.message import EmailMessage
import logging
from app.core.config import settings

logger = logging.getLogger(__name__)

def send_reset_password_email(to_email: str, otp_code: str) -> bool:
    """
    Mengirim email OTP reset password menggunakan SMTP Gmail.
    """
    if not settings.SMTP_PASSWORD:
        logger.warning(f"[EMAIL_BOT_SIMULATION] App Password belum diatur di .env. Target: {to_email} | OTP: {otp_code}")
        print(f"\n{'='*40}\n[EMAIL SIMULASI]\nTarget: {to_email}\nOTP Reset Password: {otp_code}\n{'='*40}\n")
        return True

    msg = EmailMessage()
    msg['Subject'] = 'Reset Kata Sandi Akun Kostraktor Anda'
    msg['From'] = f"Kostraktor Admin <{settings.SMTP_USER}>"
    msg['To'] = to_email

    # Konten Email
    html_content = f"""
    <html>
      <body style="font-family: Arial, sans-serif; color: #333; padding: 20px;">
        <div style="max-width: 600px; margin: 0 auto; background: #fff; border: 1px solid #ddd; border-radius: 8px; overflow: hidden;">
            <div style="background-color: #000; padding: 20px; text-align: center;">
                <h2 style="color: #fff; margin: 0;">Kostraktor</h2>
            </div>
            <div style="padding: 30px;">
                <p>Halo,</p>
                <p>Kami menerima permintaan untuk mereset kata sandi akun Kostraktor Anda.</p>
                <p>Silakan masukkan kode OTP 6-digit berikut di aplikasi untuk melanjutkan proses reset kata sandi:</p>
                
                <div style="text-align: center; margin: 30px 0;">
                    <span style="display: inline-block; padding: 15px 30px; background-color: #f4f4f4; border-radius: 8px; font-size: 32px; font-weight: bold; letter-spacing: 4px; color: #000;">
                        {otp_code}
                    </span>
                </div>
                
                <p style="color: #666; font-size: 14px;">Kode ini hanya berlaku selama 15 menit. Jika Anda tidak meminta reset kata sandi, abaikan email ini.</p>
                <br>
                <p>Salam hangat,</p>
                <p><strong>Tim Kostraktor</strong></p>
            </div>
        </div>
      </body>
    </html>
    """
    msg.set_content(f"Halo,\n\nKode OTP Anda untuk reset kata sandi adalah: {otp_code}\nKode ini berlaku 15 menit.\n\nSalam,\nTim Kostraktor")
    msg.add_alternative(html_content, subtype='html')

    try:
        # Menggunakan koneksi TLS untuk port 587
        server = smtplib.SMTP(settings.SMTP_SERVER, settings.SMTP_PORT)
        server.starttls()
        server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
        server.send_message(msg)
        server.quit()
        logger.info(f"Email reset password berhasil dikirim ke {to_email}")
        return True
    except Exception as e:
        logger.error(f"Gagal mengirim email ke {to_email}: {e}")
        print(f"SMTP EXCEPTION: {e}")
        return False
