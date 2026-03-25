const board = (() => {
   const boardBtn = document.querySelectorAll(".game_board button");
   const board = { gameBoard: [] };

   boardBtn.forEach((btn) => {
      btn.addEventListener("click", () => {
         board.gameBoard.push(btn.value);
         console.log(board);
      });
   });
})();

const player = () => {
   const player1 = {
      mark: "X",
   };
   const player2 = {
      mark: "O",
   };
};