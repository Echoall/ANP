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
  const list = document.getElementById('results');
  list.innerHTML = '';
  data.results.forEach(r => {
    const li = document.createElement('li');
    const a = document.createElement('a');
    a.href = r.webUrl;
    a.textContent = `${r.platform}：${r.webUrl}`;
    a.target = '_blank';
    if (r.deepLink) {
      a.addEventListener('click', (e) => {
        e.preventDefault();
        window.location.href = r.deepLink;
        setTimeout(() => {
          window.location.href = r.webUrl;
        }, 1500);
      });
    }
    li.appendChild(a);
    list.appendChild(li);
  });
});
