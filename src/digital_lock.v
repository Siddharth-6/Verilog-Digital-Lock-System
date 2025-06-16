module simon_say ( 
    input clk, 
    input [3:0] switches,  // SW[3:0] = 4-bit password entry 
    input enter_btn,       // Confirm button 
    input set_btn,         // New: Password set button (use SW[5] or separate button) 
    output reg [7:0] leds  // LEDs[0]=Locked, [1]=Unlocked, [2]=Lockout, [3]=ReadyToSet 
); 
 
    // State encoding 
    parameter LOCKED=0, UNLOCKED=1, LOCKOUT=2; 
    reg [1:0] state = LOCKED; 
 
    // Password storage (now writable) 
    reg [3:0] CODE = 4'b1010;  // Default code, now in reg 
 
    // Debounce registers 
    reg [3:0] enter_debounce = 0, set_debounce = 0; 
    reg enter_prev = 0, set_prev = 0; 
 
    // Attempt counter 
    reg [1:0] attempts = 0; 
 
    // Relock timer 
    reg [3:0] relock_timer = 0; 
    parameter RELOCK_TIME = 4'd15; // 15s at 1Hz 
  
    // Password change state 
    reg new_code_ready = 0; 
 
    always @(posedge clk) begin 
        // Debounce both buttons 
        enter_prev <= enter_btn; 
        set_prev <= set_btn; 
 
        if (enter_btn != enter_prev) enter_debounce <= 0; 
        else if (enter_debounce < 15) enter_debounce <= enter_debounce + 
1; 
 
        if (set_btn != set_prev) set_debounce <= 0; 
        else if (set_debounce < 15) set_debounce <= set_debounce + 1; 
 
        case(state) 
            LOCKED: begin 
                leds <= 8'b00000001;  // Red LED 
                relock_timer <= 0; 
                new_code_ready <= 0; 
 
                if ((enter_debounce == 15) && enter_btn) begin 
                    if (switches == CODE) begin 
                        state <= UNLOCKED; 
                        attempts <= 0; 
                    end else begin 
                        attempts <= attempts + 1; 
                        if (attempts == 2) state <= LOCKOUT; 
                    end 
                end 
            end 
 
            UNLOCKED: begin 
                leds <= {new_code_ready, 3'b000, 4'b0010}; // Bit7=ReadyToSet, Bit1=Unlocked 
 
                // Auto-relock after 15 seconds 
                if (relock_timer >= RELOCK_TIME) begin 
                    state <= LOCKED; 
                end else begin 
                    relock_timer <= relock_timer + 1; 
                end 
 
                // Password change logic 
                if ((set_debounce == 15) && set_btn) begin 
                    CODE <= switches;  // Set new code 
                    new_code_ready <= 1; 
                end 
 
                // Manual re-lock 
                if ((enter_debounce == 15) && enter_btn) state <= LOCKED; 
            end 
 
            LOCKOUT: begin 
                leds <= 8'b00000100;  // Lockout LED 
 
                // Auto-reset after 15 seconds 
                if (relock_timer >= 4'd15) begin 
                    state <= LOCKED; 
                    attempts <= 0; 
                end else begin 
                    relock_timer <= relock_timer + 1; 
                end 
            end 
        endcase 
    end 
 
endmodule 
