/*
Part 1 of our project refers to the Connect 4 game logic. The first draft will be simply
setting up the board: 6 rows, 7 cols. It will allow the user to move left and right
using SW[1], left, and SW[0], right. LEDR[0] will be on if the move is valid, SW[2]
allows user to place the token down. LEDR[9] will be on if there is a win. LEDR[0] will
say Player 1's turn, and LEDR[1] will say it's Player 2's turn.


Start will be KEY[1] and Resetn will be KEY[0]
*/


module legacypart1(input [2:0] SW, input CLOCK_50, input [1:0] KEY, output [9:0] LEDR);

    wire start, Resetn;
    assign start = KEY[1];
    assign Resetn = KEY[0];
    //game board and counters
    parameter empty = 2'b00, p1 = 2'b01, p2 = 2'b10;
    reg [1:0] board [0:41];
    integer i;
   
    // always @(posedge clk) begin
    // if (player_move) begin
    //     // Calculate the index based on the column and current row (based on pieces in column)
    //     integer index = calculate_board_index(column, row);
    //     board[index] <= player_id; // player_id: 2'b01 or 2'b10 based on the player
    // end
    // end


    //Setting up HSecEn
    wire [25:0] Q;
    wire HSecEn;

    register_26bit enabler(CLOCK_50, Resetn, Q);
    assign HSecEn = ~(|Q[25:0]);


    //Setting up game logic FSM
    wire right, left, place;
    reg win = 0;
    reg validMove1, validMove2;

    assign LEDR[5] = validMove2;
    assign LEDR[4] = validMove1;
    assign right = SW[0];
    assign left = SW[1];
    assign place = SW[2];
    wire shiftR, shiftL, P1_turn, P2_turn, checkwin1, checkwin2;
    FSM U1(start, Resetn, right, left, place, win, CLOCK_50, validMove1, validMove2, shiftR, shiftL, P1_turn, P2_turn, checkwin1, checkwin2);


    assign LEDR[0] = P1_turn;
    assign LEDR[1] = P2_turn;


    // Counter_currCol module
    wire [2:0] currCol;
    Counter_currCol U2(shiftR, shiftL, HSecEn, CLOCK_50, Resetn, currCol[2:0]); //Clocked by HSecEn to stop going right too quickly
    //assign LEDR[9:7] = currCol;


    // Counter_colCount module -- full code since you can't pass multi-dimensional arrays...
    // Also handles all actions of place command, (actions only happen once signalled by checkwin1/2)
    reg [2:0] colCount [0:6]; //track number of pieces in each col

    assign LEDR[9:7] = colCount[3];
    always @(posedge CLOCK_50 or negedge Resetn) begin
        if(!Resetn) begin // initialize all elements of the board
            for (i = 0; i < 42; i = i + 1) begin
                board[i] <= empty;
            end
            validMove1=0;
            validMove2=0;
            for (i = 0; i < 7; i = i + 1) begin
                colCount[i] = 3'b000;
            end
        end
        else if(checkwin1 && colCount[currCol]<3'b110) begin
            validMove1<=1;
            board[(5-colCount[currCol])*7+currCol] <= p1;
            colCount[currCol] <= colCount[currCol]+1;
        end
        else if(checkwin2 && colCount[currCol]<3'b110) begin
            validMove2<=1;
            board[(5-colCount[currCol])*7+currCol] <= p2;
            colCount[currCol] <= colCount[currCol]+1;
        end
        else if(checkwin1 && colCount[currCol]>=3'b110) begin
            validMove1 <= 0;
        end
        else if(checkwin2 && colCount[currCol]>=3'b110) begin
            validMove2 <= 0;
        end
    end

    //calc_win module -- full code
endmodule


module register_26bit(Clock, Resetn, Q);
    input Clock, Resetn;
    output reg [25:0] Q;


    always @(posedge Clock)
        if (!Resetn)
            Q <= 26'b0;
        else
            if (Q == 150000 - 1) // -->!!!real life: 25000000 - 1, DESim: 150000 - 1, ModelSim: 4 - 1 !!!<--
                Q <= 26'b0;
            else
                Q <= Q + 1;
endmodule


module Counter_currCol(input shiftR, shiftL, HSecEn, clock, Resetn, output reg [2:0] currCol);
    always @(posedge clock or negedge Resetn) begin
        if (!Resetn) begin
            currCol <= 3'b011;  // Start in middle column
        end else if (HSecEn) begin
            if (shiftR && currCol < 3'b111) 
                currCol <= currCol + 1; // Shift right
            else if (shiftL && currCol > 3'b000) 
                currCol <= currCol - 1; // Shift left
        end
    end
endmodule


module FSM(input start, Resetn, right, left, place, win, Clock, validMove1, validMove2, output shiftR, shiftL, P1_turn, P2_turn, checkwin1, checkwin2);
    reg [3:0] y, Y;
    parameter init = 4'b0000, P1 = 4'b0001, L_1 = 4'b0010, R_1 = 4'b0011, check_win1 = 4'b0100, check_win2 = 4'b0101, t_1 = 4'b0110, t_2 = 4'b0111, P2 = 4'b1000, R_2 = 4'b1001, L_2 = 4'b1010, gameOver = 4'b1011;
    always @(*)
    begin: state_table
        case (y)
            init: if (start) Y = P1;
               else Y = init;
            P1: if (right) Y = R_1;
               else if(left) Y = L_1;
               else if(place) Y = check_win1;
               else if(win) Y = gameOver;
               else Y = P1;
            R_1: if (!right) Y = P1;
               else Y = R_1;
            L_1: if (!left) Y = P1;
                 else Y = L_1;
            check_win1: Y = t_1; //we only want to place and check win once (one clock cycle)
            check_win2: Y = t_2;
            t_1: if(!validMove1&&!place) Y = P1;
                else if (!left&&!right&&!place) Y = P2; //force user to reset inputs
                else Y = t_1;
            t_2: if(!validMove2&&!place) Y = P2;
                else if (!left&&!right&&!place) Y = P1;
                else Y = t_2;
            P2: if(right) Y = R_2;
                else if(left) Y = L_2;
                else if(place) Y = check_win2;
                else if(win) Y = gameOver;
                else Y = P2;
            R_2: if(!right) Y = P2;
                else Y = R_2;
            L_2: if(!left) Y = P2;
                else Y = L_2;
            gameOver: Y = gameOver; //temp
            default: Y = 4'bxxxx;
        endcase
    end // state_table
    always @(posedge Clock)
    begin: state_FFs
        if(!Resetn)
            y<=init;
        else
            y<=Y;
    end // state_FFS
    assign P1_turn = (~y[3]&~y[2]&~y[1]&y[0])|(~y[3]&y[2]&~y[1]&~y[0]); // P1, check_win1
    assign P2_turn = (y[3]&~y[2]&~y[1]&~y[0])|(~y[3]&y[2]&~y[1]&y[0]); // P2, check_win2
    assign shiftR = (~y[3]&~y[2]&y[1]&y[0])|(y[3]&~y[2]&~y[1]&y[0]); // R_1, R_2
    assign shiftL = (~y[3]&~y[2]&y[1]&~y[0])|(y[3]&~y[2]&y[1]&~y[0]); // L_1, L_2
    assign checkwin1 = (~y[3]&y[2]&~y[1]&~y[0]); // check_win1
    assign checkwin2 = (~y[3]&y[2]&~y[1]&y[0]); // check_win2
endmodule
