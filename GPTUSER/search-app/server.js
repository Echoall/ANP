const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.static(path.join(__dirname, 'public')));
app.use(express.json());

// Build web and deep links for a platform search.
// Detects iOS user agents to return a deep-link URL scheme
// so the client can attempt to open the native app.
function buildSearchLink(platform, query, userAgent = '') {
  const q = encodeURIComponent(query);
  const isIOS = /iPad|iPhone|iPod/.test(userAgent);

  const webLinks = {
    xiaohongshu: `https://www.xiaohongshu.com/search_result?keyword=${q}`,
    baidu: `https://www.baidu.com/s?wd=${q}`,
    douyin: `https://www.douyin.com/search/${q}`,
    bilibili: `https://search.bilibili.com/all?keyword=${q}`,
  };

  // iOS deep-link schemes for each platform. These may only work on
  // devices with the corresponding apps installed.
  const deepLinks = {
    xiaohongshu: `xiaohongshu://search/result?keyword=${q}`,
    baidu: `baiduboxapp://s?word=${q}`,
    douyin: `snssdk1128://search?keyword=${q}`,
    bilibili: `bilibili://search?keyword=${q}`,
  };

  return {
    platform,
    webUrl: webLinks[platform] || '#',
    deepLink: isIOS ? deepLinks[platform] || null : null,
  };
}

app.post('/search', (req, res) => {
  const { query, platforms } = req.body;
  if (!query || !Array.isArray(platforms)) {
    return res.status(400).json({ error: 'Invalid request' });
  }
  const ua = req.headers['user-agent'] || '';
  const results = platforms.map((p) => buildSearchLink(p, query, ua));
  res.json({ results });
});

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
