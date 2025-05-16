document.addEventListener("DOMContentLoaded", () => {
  const unameEl = document.getElementById("username");
  if (unameEl) unameEl.textContent = USERNAME;

  fetchUnlocked();
  updateProfileInfo();
});

function switchView(id) {
  document.querySelectorAll('.view').forEach(view => view.style.display = 'none');
  const target = document.getElementById(id);
  if (target) target.style.display = 'block';
  if (id === 'events') {
    fetchEvents();
    fetchJoinedEvents();
  }
}

const unlocked = new Set();

async function fetchUnlocked() {
  const res = await fetch("/get_unlocked");
  const data = await res.json();
  for (const id of data.unlocked_ids) {
    unlocked.add(id);
  }
  renderDex();
  updateProfileInfo();
}

function renderDex() {
  const dexList = document.getElementById("dexList");
  if (!dexList) return;
  dexList.innerHTML = '';
  for (let id in DEX) {
    const item = DEX[id];
    const imgSrc = unlocked.has(id) ? item.image : "/static/dex/unknow.png";
    const cardClass = unlocked.has(id) ? "card" : "card locked";
    dexList.innerHTML += `
      <div class="${cardClass}">
        <img src="${imgSrc}" alt="Trash">
        <p>${item.name}</p>
        <p>#${id}</p>
      </div>`;
  }
}

function updateProfileInfo() {
  const unlockedCount = document.getElementById("unlockedCount");
  if (unlockedCount) unlockedCount.textContent = unlocked.size;

  fetch("/get_token_count")
    .then(res => res.json())
    .then(data => {
      const tokenCount = document.getElementById("tokenCount");
      if (tokenCount) tokenCount.textContent = data.tokens || 0;
    });
}

const uploadForm = document.getElementById("uploadForm");
const imageInput = document.getElementById("imageInput");
const preview = document.getElementById("preview");

uploadForm?.addEventListener("submit", async (e) => {
  e.preventDefault();
  const file = imageInput.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = () => {
    preview.innerHTML = `<img src="${reader.result}" alt="Preview" style="max-width:100%; border-radius:8px; margin-top:10px;">`;
  };
  reader.readAsDataURL(file);

  const formData = new FormData();
  formData.append("image", file);

  const res = await fetch("/analyze_trash", {
    method: "POST",
    body: formData
  });

  const data = await res.json();
  const result = document.getElementById("result");

  if (data.unlocked_id) {
    unlocked.add(data.unlocked_id);
    result.innerHTML = `
      <h3>🔍 Recognized: ${data.unlocked_name}</h3>
      <img src="${data.unlocked_image}" alt="Trash" style="max-width:100px;">
      <p>ID: ${data.unlocked_id}</p>
    `;
  } else {
    result.innerHTML = `<h3>❌ Unable to recognize</h3>`;
  }

  renderDex();
  updateProfileInfo();
});

async function fetchEvents() {
  const res = await fetch('/get_events');
  const data = await res.json();
  const container = document.getElementById("eventList");
  if (!container) return;
  container.innerHTML = '';
  data.events.forEach(event => {
    container.innerHTML += `
      <div class="card">
        <h4>${event.title}</h4>
        <p>${event.location}</p>
        <p>${event.datetime}</p>
        <button onclick="joinEvent('${event.id}')">Join</button>
      </div>`;
  });
}

async function fetchJoinedEvents() {
  const res = await fetch('/get_joined_events');
  const data = await res.json();
  const container = document.getElementById("joinedList");
  if (!container) return;
  container.innerHTML = '';
  data.events.forEach(event => {
    container.innerHTML += `
      <div class="card">
        <h4>${event.title}</h4>
        <p>${event.location}</p>
        <p>${event.datetime}</p>
        <span>✅ Joined</span>
      </div>`;
  });
}

async function joinEvent(eventId) {
  const res = await fetch(`/join_event/${eventId}`, { method: "POST" });
  const data = await res.json();
  alert(data.status === "joined" ? "成功加入活動並獲得代幣！" : "您已參加過此活動");
  fetchEvents();
  fetchJoinedEvents();
  updateProfileInfo();
}
