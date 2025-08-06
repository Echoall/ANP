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
    a.href = r.url;
    a.textContent = `${r.platform}：${r.url}`;
    a.target = '_blank';
    li.appendChild(a);
    list.appendChild(li);
  });
});
