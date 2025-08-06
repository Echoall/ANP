const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.static(path.join(__dirname, 'public')));
app.use(express.json());

function buildSearchLink(platform, query) {
  const q = encodeURIComponent(query);
  switch (platform) {
    case 'xiaohongshu':
      return `https://www.xiaohongshu.com/search_result?keyword=${q}`;
    case 'baidu':
      return `https://www.baidu.com/s?wd=${q}`;
    case 'douyin':
      return `https://www.douyin.com/search/${q}`;
    case 'bilibili':
      return `https://search.bilibili.com/all?keyword=${q}`;
    default:
      return '#';
  }
}

app.post('/search', (req, res) => {
  const { query, platforms } = req.body;
  if (!query || !Array.isArray(platforms)) {
    return res.status(400).json({ error: 'Invalid request' });
  }
  const results = platforms.map((p) => ({ platform: p, url: buildSearchLink(p, query) }));
  res.json({ results });
});

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
