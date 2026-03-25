// DROPDOWN
const dropdown = document.addEventListener('click', (e) => {
   document.querySelectorAll('.dropdown-content').forEach((el) => {
      if (el !== e.target) el.classList.remove('show');
   });
   if (e.target.matches('.dropbtn')) {
      e.target
         .closest('.dropdown')
         .querySelector('.dropdown-content')
         .classList.add('show');
   }
});

// DROPDOWN HOVER
// the content is not keep when the hover is removed
const dropdownHover = document.addEventListener('mouseover', (e) => {
   document.querySelectorAll('.dropdown-content-hover').forEach((el) => {
      if (el !== e.target) el.classList.remove('show');
   });
   if (e.target.matches('.dropbtn-hover')) {
      e.target
         .closest('.dropdown-hover')
         .querySelector('.dropdown-content-hover')
         .classList.add('show');
   }
});

// CAROUSEL
const before = document.querySelector('.prev');
const next = document.querySelector('.next');
const imgs = document.querySelectorAll('.img-container img');

let indexImg = 0;
let intervalId = null;

document.addEventListener('DOMContentLoaded', initializer);

function initializer() {
   imgs[indexImg].classList.add('display');
   intervalId = setInterval(nextImg, 3000);
}

function startInterval() {
   intervalId = setInterval(nextImg, 3000);
}

function showImg(index) {
   if (index >= imgs.length) {
      indexImg = 0;
   } else if (index < 0) {
      indexImg = imgs.length - 1;
   }
   imgs.forEach((img) => {
      img.classList.remove('display');
   });
   imgs[indexImg].classList.add('display');
}

function nextImg() {
   intervalId = clearInterval(intervalId);
   indexImg++;
   showImg(indexImg);
   startInterval();
}

function prevImg() {
   intervalId = clearInterval(intervalId);
   indexImg--;
   showImg(indexImg);
   startInterval();
}
