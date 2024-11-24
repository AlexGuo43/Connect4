
module vga_demo(
    CLOCK_50, SW, KEY, Resetn, board_0, board_1, board_2, board_3, board_4, board_5, board_6,
    board_7, board_8, board_9, board_10, board_11, board_12, board_13,
    board_14, board_15, board_16, board_17, board_18, board_19, board_20,
    board_21, board_22, board_23, board_24, board_25, board_26, board_27,
    board_28, board_29, board_30, board_31, board_32, board_33, board_34,
    board_35, board_36, board_37, board_38, board_39, board_40, board_41,
    VGA_R, VGA_G, VGA_B,
    VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK
);

    input CLOCK_50;    
    input [9:0] SW;         // SW[9] used to select object
    input [3:0] KEY;
    input Resetn;
	input [1:0] board_0, board_1, board_2, board_3, board_4, board_5, board_6,
                board_7, board_8, board_9, board_10, board_11, board_12, board_13,
                board_14, board_15, board_16, board_17, board_18, board_19, board_20,
                board_21, board_22, board_23, board_24, board_25, board_26, board_27,
                board_28, board_29, board_30, board_31, board_32, board_33, board_34,
                board_35, board_36, board_37, board_38, board_39, board_40, board_41;
    output [7:0] VGA_R;     // VGA Red color signal
    output [7:0] VGA_G;     // VGA Green color signal
    output [7:0] VGA_B;     // VGA Blue color signal
    output VGA_HS;          // VGA Horizontal Sync
    output VGA_VS;          // VGA Vertical Sync
    output VGA_BLANK_N;     // VGA Blank signal
    output VGA_SYNC_N;      // VGA Sync signal
    output VGA_CLK;         // VGA Clock signal

    wire [7:0] X;           // starting X location 
    wire [6:0] Y;           // starting Y location 
	reg [7:0] calc_X;           // starting X location 
    reg [6:0] calc_Y;           // starting Y location 
    wire [2:0] XC, YC;      // used to access object memory
    wire Ex, Ey;
    wire [7:0] VGA_X;       // x location of each object pixel
    wire [6:0] VGA_Y;       // y location of each object pixel
    wire [2:0] VGA_COLOR;   // color of each object pixel
    reg P2_turn;
	 
    reg [1:0] prev_board [0:41]; // Store the previous state of the board
    reg [1:0] board_internal [0:41]; // local copy of game logic's board, updated every clock cycle
    reg update_screen;
    integer i;
    reg [2:0] currCol, currRow;
    // trying to imitate released_key duration
    reg [15:0] delay_counter; // 16-bit counter for delay
    reg updating_screen;      // Holds the extended `update_screen`

    always @(posedge CLOCK_50 or negedge Resetn) begin
        if (!Resetn) begin
            // Reset logic
            for (i = 0; i < 42; i = i + 1) begin
                prev_board[i] <= 2'b00;
            end
            update_screen <= 0;
            P2_turn <= 0;
            delay_counter <= 0;
            updating_screen <= 0;
        end else begin
            // Update current state
            board_internal[0] <= board_0;
            board_internal[1] <= board_1;
            board_internal[2] <= board_2;
            board_internal[3] <= board_3;
            board_internal[4] <= board_4;
            board_internal[5] <= board_5;
            board_internal[6] <= board_6;
            board_internal[7] <= board_7;
            board_internal[8] <= board_8;
            board_internal[9] <= board_9;
            board_internal[10] <= board_10;
            board_internal[11] <= board_11;
            board_internal[12] <= board_12;
            board_internal[13] <= board_13;
            board_internal[14] <= board_14;
            board_internal[15] <= board_15;
            board_internal[16] <= board_16;
            board_internal[17] <= board_17;
            board_internal[18] <= board_18;
            board_internal[19] <= board_19;
            board_internal[20] <= board_20;
            board_internal[21] <= board_21;
            board_internal[22] <= board_22;
            board_internal[23] <= board_23;
            board_internal[24] <= board_24;
            board_internal[25] <= board_25;
            board_internal[26] <= board_26;
            board_internal[27] <= board_27;
            board_internal[28] <= board_28;
            board_internal[29] <= board_29;
            board_internal[30] <= board_30;
            board_internal[31] <= board_31;
            board_internal[32] <= board_32;
            board_internal[33] <= board_33;
            board_internal[34] <= board_34;
            board_internal[35] <= board_35;
            board_internal[36] <= board_36;
            board_internal[37] <= board_37;
            board_internal[38] <= board_38;
            board_internal[39] <= board_39;
            board_internal[40] <= board_40;
            board_internal[41] <= board_41;

            // Check for board changes
            if (!updating_screen) begin
                update_screen <= 0;
                for (i = 0; i < 42; i = i + 1) begin
                    if (board_internal[i] !== prev_board[i]) begin
                        currCol = i % 7; // Calculate current column
                        currRow = i / 7; // Calculate current row
                        if (board_internal[i] == 2'b10)
                            P2_turn <= 1;
                        else
                            P2_turn <= 0;
                        calc_X <= 37 + 13 * currCol;
                        calc_Y <= 89 - 13 * (5-currRow);
                        update_screen <= 1;
                        updating_screen <= 1; // Start delay extension
                        delay_counter <= 0;  // Reset counter
                        prev_board[i] <= board_internal[i];
                    end
                end
            end else begin
                // Extend `update_screen` duration
                delay_counter <= delay_counter + 1;
                if (delay_counter >= 50000) begin // 50,000 clock cycles (~1 ms)
                    updating_screen <= 0; // End the extension
                end
            end
        end
    end


    // Store (x, y) starting location
	 // Changing to KEY[1] and KEY[2] to just be KEY[2] to update both X and Y
    regn U1 (calc_Y, KEY[0], update_screen, CLOCK_50, Y);
        defparam U1.n = 7;
    regn U2 (calc_X, KEY[0], update_screen, CLOCK_50, X);
        defparam U2.n = 8;

    // Column and Row Counters
    count U3 (CLOCK_50, KEY[0], Ex, XC);    // column counter
        defparam U3.n = 3;
    //regn U5 (1'b1, KEY[0], ~KEY[3], CLOCK_50, Ex);  // enable XC when VGA plotting starts
	 regn U5 (1'b1, KEY[0], update_screen , CLOCK_50, Ex);
        defparam U5.n = 1;
    count U4 (CLOCK_50, KEY[0], Ey, YC);    // row counter
        defparam U4.n = 3;
    assign Ey = (XC == 3'b111);             // enable YC at the end of each object row



    // Instantiate two object memories
    wire [2:0] color_object1, color_object2;

    // Object 1 memory (from object1.mif)
    object_mem1 U6_object1 (
        .address({YC, XC}),
        .clock(CLOCK_50),
        .q(color_object1)
    );

    // Object 2 memory (from object2.mif)
    object_mem2 U6_object2 (
        .address({YC, XC}),
        .clock(CLOCK_50),
        .q(color_object2)
    );

    // Select color output based on SW[9]
    assign VGA_COLOR = P2_turn ? color_object1 : color_object2;

    // The object memory takes one clock cycle to provide data, so store
    // the current values of (x, y) addresses to remain synchronized
    regn U7 (X + XC, KEY[0], 1'b1, CLOCK_50, VGA_X);
        defparam U7.n = 8;
    regn U8 (Y + YC, KEY[0], 1'b1, CLOCK_50, VGA_Y);
        defparam U8.n = 7;

    // Connect to VGA controller
    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),
        .colour(VGA_COLOR),
        .x(VGA_X),
        .y(VGA_Y),
        //.plot(~KEY[3]),
		  .plot(update_screen),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );
    defparam VGA.RESOLUTION = "160x120";
    defparam VGA.MONOCHROME = "FALSE";
    defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
    defparam VGA.BACKGROUND_IMAGE = "image.colour.mif";

endmodule

// regn module
module regn (R, Resetn, E, Clock, Q);
    parameter n = 8;
    input [n-1:0] R;
    input Resetn, E, Clock;
    output reg [n-1:0] Q;

    always @(posedge Clock)
        if (!Resetn)
            Q <= 0;
        else if (E)
            Q <= R;
endmodule

// count module
module count (Clock, Resetn, E, Q);
    parameter n = 8;
    input Clock, Resetn, E;
    output reg [n-1:0] Q;

    always @(posedge Clock)
        if (Resetn == 0)
            Q <= 0;
        else if (E)
            Q <= Q + 1;
endmodule

