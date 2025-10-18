// Theme Toggle
const toggle = document.getElementById("themeToggle");
const body = document.body;

toggle.addEventListener("change", () => {
  body.classList.toggle("light-mode");
});

