# ⚠️ Restart Required

The `.env.local` file has been updated to point to your local backend:

```
NEXT_PUBLIC_API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## 🔄 Next Steps:

1. **Stop the Next.js dev server** (Ctrl+C in the terminal)

2. **Start it again:**
   ```bash
   cd kostraktor-admin
   npm run dev
   ```

3. **Make sure your backend is running:**
   ```bash
   cd backend
   python -m uvicorn app.main:app --reload
   ```

4. **Try logging in again with:**
   ```
   Email: admin@kostraktor.com
   Password: admin123
   ```

## Why This Was Needed

The admin dashboard was trying to authenticate against the remote production server instead of your local backend, which is why you got a 401 error.

After restarting the Next.js server, it will use your local backend at `http://127.0.0.1:8000/api/v1`.
