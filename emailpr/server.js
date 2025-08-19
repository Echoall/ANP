const express = require('express');
const multer = require('multer');
const nodemailer = require('nodemailer');
const cron = require('node-cron');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));

const dataDir = path.join(__dirname, 'data');
const uploadsDir = path.join(dataDir, 'uploads');
const categoriesFile = path.join(dataDir, 'emailCategories.json');
const queueFile = path.join(dataDir, 'sendQueue.json');

fs.mkdirSync(uploadsDir, { recursive: true });
if (!fs.existsSync(categoriesFile)) fs.writeFileSync(categoriesFile, '{}');
if (!fs.existsSync(queueFile)) fs.writeFileSync(queueFile, '[]');

const upload = multer({ dest: uploadsDir });

function loadJson(file, defaultValue) {
  try {
    return JSON.parse(fs.readFileSync(file));
  } catch (err) {
    return defaultValue;
  }
}

function saveJson(file, data) {
  fs.writeFileSync(file, JSON.stringify(data, null, 2));
}

app.get('/api/categories', (req, res) => {
  const categories = loadJson(categoriesFile, {});
  res.json(categories);
});

app.post('/api/add-email', (req, res) => {
  const { category, email } = req.body;
  if (!category || !email) return res.status(400).send('缺少必要字段');
  const categories = loadJson(categoriesFile, {});
  categories[category] = categories[category] || [];
  categories[category].push(email);
  saveJson(categoriesFile, categories);
  res.send('邮箱已添加');
});

app.post('/api/upload', upload.single('file'), (req, res) => {
  const { emailCategory, contentCategory, text, schedule } = req.body;
  if (!emailCategory || !schedule) return res.status(400).send('缺少必要字段');
  const queue = loadJson(queueFile, []);
  queue.push({
    emailCategory,
    contentCategory,
    text,
    filepath: req.file ? req.file.path : null,
    schedule
  });
  saveJson(queueFile, queue);
  res.send('已加入发送队列');
});

cron.schedule('* * * * *', () => {
  const queue = loadJson(queueFile, []);
  const now = new Date();
  const remaining = [];
  queue.forEach(item => {
    if (new Date(item.schedule) <= now) {
      sendEmail(item);
    } else {
      remaining.push(item);
    }
  });
  saveJson(queueFile, remaining);
});

async function sendEmail(item) {
  const categories = loadJson(categoriesFile, {});
  const recipients = categories[item.emailCategory] || [];
  if (recipients.length === 0) return;
  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: false,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS
    }
  });
  const mailOptions = {
    from: process.env.SMTP_USER,
    to: recipients.join(','),
    subject: item.contentCategory || '通知',
    text: item.text || '请查看附件',
    attachments: item.filepath ? [{ path: item.filepath }] : []
  };
  try {
    await transporter.sendMail(mailOptions);
    console.log('已发送到', recipients);
  } catch (err) {
    console.error('发送错误', err);
  }
}

app.listen(PORT, () => {
  console.log(`服务器已在端口 ${PORT} 运行`);
});
