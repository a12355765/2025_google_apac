document.addEventListener("DOMContentLoaded", function () {
    const form = document.querySelector("form");
    const username = document.querySelector("input[name='username']");
    const password = document.querySelector("input[name='password']");

    form.addEventListener("submit", function (e) {
        if (!username.value.trim() || !password.value.trim()) {
            e.preventDefault();
            alert("Please fill in both username and password.");
        }
    });
});
