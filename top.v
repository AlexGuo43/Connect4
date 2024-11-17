// Copyright (c) 2020 FPGAcademy
// Please see license at https://github.com/fpgacademy/DESim

module top (CLOCK_50, SW, KEY, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR);

    input CLOCK_50;             // DE-series 50 MHz clock signal
    input wire [9:0] SW;        // DE-series switches
    input wire [3:0] KEY;       // DE-series pushbuttons

    output wire [6:0] HEX0;     // DE-series HEX displays
    output wire [6:0] HEX1;
    output wire [6:0] HEX2;
    output wire [6:0] HEX3;
    output wire [6:0] HEX4;
    output wire [6:0] HEX5;

    // wire [7:0] received_data;       // Data from PS/2 keyboard
    // wire received_data_en;          // Data valid signal

    // PS2_Controller ps2 (
    //     .CLOCK_50(CLOCK_50),       // System clock
    //     .reset(~KEY[0]),           // Active-high reset
    //     .PS2_CLK(PS2_CLK),         // PS/2 Clock line
    //     .PS2_DAT(PS2_DAT),         // PS/2 Data line
    //     .received_data(received_data[7:0]),
    //     .received_data_en(received_data_en)
    // );

    output wire [9:0] LEDR;     // DE-series LEDs   

    legacypart1 U1 (SW[2:0], CLOCK_50, KEY[1:0], LEDR);

endmodule

