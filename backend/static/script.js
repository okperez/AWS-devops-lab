async function checkHealth() {
  const statusElement = document.getElementById('status');

  try {
    const response = await fetch('/health');
    const data = await response.json();
    statusElement.textContent = data.status === 'ok' ? 'OK' : 'Erreur';
    statusElement.style.color = data.status === 'ok' ? '#15803d' : '#b91c1c';
  } catch (error) {
    statusElement.textContent = 'Indisponible';
    statusElement.style.color = '#b91c1c';
  }
}

document.getElementById('refresh-button').addEventListener('click', checkHealth);
checkHealth();
