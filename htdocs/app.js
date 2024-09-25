let submitButton = document.getElementById("submit_button");
let accessForm = document.getElementById("access_form");
let voucherToken = document.getElementById("voucher");
let macAddress = document.getElementById("macAddress");
let ipAddress = document.getElementById("ipAddress");
let router = document.getElementById("router");
let success = document.getElementById("success");
let error = document.getElementById("error");
let password = document.getElementById("password");
let username = document.getElementById("username");
let details = document.getElementById("details");
let description = document.getElementById("description");
async function CheckValidity() {
  submitButton.innerText = "Loading...";
  let disabledAttr = document.createAttribute("disabled");
  submitButton.attributes.setNamedItem(disabledAttr);
  const myHeaders = new Headers();
  myHeaders.append("Content-Type", "application/json");
  const raw = JSON.stringify({
    macAddress: macAddress.value,
    userAgent: navigator.userAgent.match(/\(([^)]+)\)/)[1],
    router: router.value,
    ipAddress: ipAddress.value,
  });
  const requestOptions = {
    method: "POST",
    headers: myHeaders,
    body: raw,
    redirect: "follow",
  };
  try {
    let res = await fetch(
      "https://bixbdwifi.vercel.app/api/v1/get-token",
      requestOptions
    );
    let response = await res.json();
    if (response.success) {
      error.style.display = "none";
      success.style.display = "flex";
      success.innerText = response.message;
      password.value = response.timeLeft;
      username.value = voucherToken.value;
      details.innerText = response.validity + " Package";
      description.style.display = "none";
      localStorage.setItem("voucherToken", voucherToken.value);
      accessForm.submit();
    }
    submitButton.innerText = "Enter";
    submitButton.attributes.removeNamedItem("disabled");
  } catch (error) {
    submitButton.innerText = "Enter";
    submitButton.attributes.removeNamedItem("disabled");
    localStorage.clear();
  }
}

CheckValidity();

document
  .getElementById("submit_button")
  .addEventListener("click", async function (e) {
    e.preventDefault();
    if (!voucherToken.value || voucherToken.value.length < 8) {
      error.style.display = "flex";
      error.innerText = "The token must be in 8 Digit";
      return;
    }
    submitButton.innerText = "Loading...";
    let disabledAttr = document.createAttribute("disabled");
    submitButton.attributes.setNamedItem(disabledAttr);
    const myHeaders = new Headers();
    myHeaders.append("Content-Type", "application/json");
    const raw = JSON.stringify({
      token: voucherToken.value,
      macAddress: macAddress.value,
      userAgent: navigator.userAgent.match(/\(([^)]+)\)/)[1],
      router: router.value,
      ipAddress: ipAddress.value,
    });
    const requestOptions = {
      method: "POST",
      headers: myHeaders,
      body: raw,
      redirect: "follow",
    };

    try {
      let res = await fetch(
        "https://bixbdwifi.vercel.app/api/v1/validate",
        requestOptions
      );
      let response = await res.json();

      if (response.success) {
        error.style.display = "none";
        success.style.display = "flex";
        success.innerText = response.message;
        password.value = response.timeLeft;
        username.value = voucherToken.value;
        details.innerText = response.validity + " Package";
        description.style.display = "none";
        accessForm.submit();
      } else {
        success.style.display = "none";
        error.style.display = "flex";
        error.innerText = response.message;
      }

      submitButton.innerText = "Enter";
      submitButton.attributes.removeNamedItem("disabled");
    } catch (error) {
      console.log(error.message);
      submitButton.innerText = "Enter";
      submitButton.attributes.removeNamedItem("disabled");
    }
  });
