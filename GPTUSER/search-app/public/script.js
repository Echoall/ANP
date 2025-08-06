let latestResults = [];

function openLink(r) {
  if (r.deepLink) {
    const win = window.open(r.deepLink, '_blank');
    setTimeout(() => {
      try {
        if (win) {
          win.location = r.webUrl;
        } else {
          window.open(r.webUrl, '_blank');
        }
      } catch (e) {
        window.open(r.webUrl, '_blank');
      }
    }, 1500);
  } else {
    window.open(r.webUrl, '_blank');
  }
}

document.getElementById('searchBtn').addEventListener('click', async () => {
  const query = document.getElementById('query').value.trim();
  if (!query) return;
  const platforms = Array.from(document.querySelectorAll('.platforms input:checked')).map(i => i.value);
  const res = await fetch('/search', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query, platforms })
  });
  const data = await res.json();
  latestResults = data.results;
  const list = document.getElementById('results');
  list.innerHTML = '';
  latestResults.forEach(r => {
    const li = document.createElement('li');
    const a = document.createElement('a');
    a.href = r.webUrl;
    a.textContent = `${r.platform}：${r.webUrl}`;
    a.target = '_blank';
    a.addEventListener('click', (e) => {
      e.preventDefault();
      openLink(r);
    });
    li.appendChild(a);
    list.appendChild(li);
  });
  const openAllBtn = document.getElementById('openAllBtn');
  openAllBtn.style.display = latestResults.length ? 'inline-block' : 'none';
});

document.getElementById('openAllBtn').addEventListener('click', () => {
  latestResults.forEach(r => openLink(r));
});
