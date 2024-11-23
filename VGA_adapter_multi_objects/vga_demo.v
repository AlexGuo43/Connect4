/*
*   Displays a pattern, which is read from a small memory, at (x,y) on the VGA output.
*   To set coordinates, first place the desired value of y onto SW[6:0] and press KEY[1].
*   Next, place the desired value of x onto SW[7:0] and then press KEY[2]. The (x,y)
*   coordinates are displayed (in hexadecimal) on (HEX3-2,HEX1-0). Finally, press KEY[3]
*   to draw the pattern at location (x,y).
*   SW[9] selects between two different objects (each with its own MIF file).
*/
module vga_demo(
    CLOCK_50, SW, KEY, P1_turn, P2_turn, place, currCol, colCount0, colCount1,colCount2,colCount3,colCount4,colCount5,colCount6, HEX3, HEX2, HEX1, HEX0,
    VGA_R, VGA_G, VGA_B,
    VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK
);

    input CLOCK_50;    
    input [9:0] SW;         // SW[9] used to select object
    input [3:0] KEY;
	 input P1_turn;
	 input P2_turn;
	 input place;
	 input [2:0] currCol;
	 input [2:0] colCount0;
	 input [2:0] colCount1;
	 input [2:0] colCount2;
	 input [2:0] colCount3;
	 input [2:0] colCount4;
	 input [2:0] colCount5;
	 input [2:0] colCount6;
    output [6:0] HEX3, HEX2, HEX1, HEX0;
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
	 wire [7:0] calc_X;           // starting X location 
    reg [6:0] calc_Y;           // starting Y location 
    wire [2:0] XC, YC;      // used to access object memory
    wire Ex, Ey;
    wire [7:0] VGA_X;       // x location of each object pixel
    wire [6:0] VGA_Y;       // y location of each object pixel
    wire [2:0] VGA_COLOR;   // color of each object pixel
	 
	 /*wire [2:0] currCol = SW[2:0];    
    reg [2:0] colCount [0:6];  
	 always @(*) begin
        case (currCol)
            3'b000: colCount[0] = SW[5:3];
            3'b001: colCount[1] = SW[5:3];
            3'b010: colCount[2] = SW[5:3];
            3'b011: colCount[3] = SW[5:3];
            3'b100: colCount[4] = SW[5:3];
            3'b101: colCount[5] = SW[5:3];
            3'b110: colCount[6] = SW[5:3];
            default: colCount[currCol] = 3'b000;
        endcase
    end*/
	 always @(posedge CLOCK_50) begin
		 case (currCol)
			  3'b000: calc_Y = 89 - 13 * (colCount0 > 5 ? 5 : colCount0);
			  3'b001: calc_Y = 89 - 13 * (colCount1 > 5 ? 5 : colCount1);
			  3'b010: calc_Y = 89 - 13 * (colCount2 > 5 ? 5 : colCount2);
			  3'b011: calc_Y = 89 - 13 * (colCount3 > 5 ? 5 : colCount3);
			  3'b100: calc_Y = 89 - 13 * (colCount4 > 5 ? 5 : colCount4);
			  3'b101: calc_Y = 89 - 13 * (colCount5 > 5 ? 5 : colCount5);
			  3'b110: calc_Y = 89 - 13 * (colCount6 > 5 ? 5 : colCount6);
			  default: calc_Y = 89;
		 endcase
	 end
	 assign calc_X = 37+13*currCol;
	 //assign calc_Y = 89 - 13 * colCount[currCol];

    // Store (x, y) starting location
	 // Changing to KEY[1] and KEY[2] to just be KEY[2] to update both X and Y
    regn U1 (calc_Y, KEY[0], place, CLOCK_50, Y);
        defparam U1.n = 7;
    regn U2 (calc_X, KEY[0], place, CLOCK_50, X);
        defparam U2.n = 8;

    // Column and Row Counters
    count U3 (CLOCK_50, KEY[0], Ex, XC);    // column counter
        defparam U3.n = 3;
    //regn U5 (1'b1, KEY[0], ~KEY[3], CLOCK_50, Ex);  // enable XC when VGA plotting starts
	 regn U5 (1'b1, KEY[0], place , CLOCK_50, Ex);
        defparam U5.n = 1;
    count U4 (CLOCK_50, KEY[0], Ey, YC);    // row counter
        defparam U4.n = 3;
    assign Ey = (XC == 3'b111);             // enable YC at the end of each object row

    hex7seg H3 (X[7:4], HEX3);
    hex7seg H2 (X[3:0], HEX2);
    hex7seg H1 ({1'b0, Y[6:4]}, HEX1);
    hex7seg H0 (Y[3:0], HEX0);

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
		  .plot(place),
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

// hex7seg module
module hex7seg (hex, display);
    input [3:0] hex;
    output [6:0] display;
    reg [6:0] display;

    always @ (hex)
        case (hex)
            4'h0: display = 7'b1000000;
            4'h1: display = 7'b1111001;
            4'h2: display = 7'b0100100;
            4'h3: display = 7'b0110000;
            4'h4: display = 7'b0011001;
            4'h5: display = 7'b0010010;
            4'h6: display = 7'b0000010;
            4'h7: display = 7'b1111000;
            4'h8: display = 7'b0000000;
            4'h9: display = 7'b0011000;
            4'hA: display = 7'b0001000;
            4'hB: display = 7'b0000011;
            4'hC: display = 7'b1000110;
            4'hD: display = 7'b0100001;
            4'hE: display = 7'b0000110;
            4'hF: display = 7'b0001110;
        endcase
endmodule