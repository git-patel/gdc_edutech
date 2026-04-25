document.addEventListener('DOMContentLoaded', () => {
  // Theme Toggle
  const themeToggle = document.getElementById('themeToggle');
  const THEME_KEY = 'learnflow-theme';

  function applyTheme(isDark) {
    if (isDark) {
      document.documentElement.setAttribute('data-theme', 'dark');
      if(themeToggle) themeToggle.innerHTML = '<i class="fas fa-sun"></i>';
    } else {
      document.documentElement.removeAttribute('data-theme');
      if(themeToggle) themeToggle.innerHTML = '<i class="fas fa-moon"></i>';
    }
  }

  const savedTheme = localStorage.getItem(THEME_KEY);
  if (savedTheme === 'dark') {
    applyTheme(true);
  } else {
    applyTheme(false);
  }

  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
      applyTheme(!isDark);
      localStorage.setItem(THEME_KEY, !isDark ? 'dark' : 'light');
    });
  }

  // Footer Year
  const yearSpan = document.getElementById('year');
  if (yearSpan) {
    yearSpan.textContent = new Date().getFullYear();
  }
});

// Function to launch the Flutter App
function launchApp() {
  document.getElementById('landing-site').style.display = 'none';
  const appContainer = document.getElementById('app-container');
  if (appContainer) {
    appContainer.style.display = 'block';
  }

  // Initialize Flutter
  const script = document.createElement('script');
  script.src = 'flutter_bootstrap.js';
  script.async = true;
  document.body.appendChild(script);
}
