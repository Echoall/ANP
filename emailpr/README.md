# emailpr

A minimal web application for uploading content and automatically sending emails to categorized recipients with scheduling.

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```
2. Create a `.env` file with your SMTP credentials:
   ```env
   SMTP_HOST=smtp.example.com
   SMTP_PORT=587
   SMTP_USER=your@example.com
   SMTP_PASS=yourpassword
   ```
   The server will automatically create all required data files on first run, so no manual setup is needed.
3. (Optional) copy the example categories file:
   ```bash
   cp data/emailCategories.example.json data/emailCategories.json
   ```
   Edit `data/emailCategories.json` to list recipients for each category.

## Running

```bash
node server.js
```
Visit [http://localhost:3000](http://localhost:3000) to use the web interface. Uploaded content and scheduling information are stored in the `data` directory, and any files you upload are saved under `data/uploads/`.

Emails are checked for sending every minute using `node-cron`.

Use the date/time picker on the page to schedule messages in your local time.
