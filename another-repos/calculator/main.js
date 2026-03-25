const display = document.querySelector(".display");
const buttons = document.querySelectorAll("button");
let output = "";

const calculate = (btnValue) => {
   if (btnValue === "AC") {
      output = "";
   } else {
      output = btnValue;
   }

   display.value = output;
};

buttons.h((button) => {
   button.addEventListener("click", (e) => calculate(e.target.dataset.value));
});
