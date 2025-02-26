module battleship (
    input            clk  ,
    input            rst  ,
    input            start,
    input      [1:0] X    ,
    input      [1:0] Y    ,
    input            pAb  ,
    input            pBb  ,
    output reg [7:0] disp0,
    output reg [7:0] disp1,
    output reg [7:0] disp2,
    output reg [7:0] disp3,
    output reg [7:0] led
);

  // ----------------------------------------------------------------
  // Define states
  // ----------------------------------------------------------------
  parameter IDLE        = 4'b0000;
  parameter SHOW_A      = 4'b0001;
  parameter A_IN        = 4'b0010;
  parameter ERROR_A     = 4'b0011;
  parameter SHOW_B      = 4'b0100;
  parameter B_IN        = 4'b0101;
  parameter ERROR_B     = 4'b0110;
  parameter SHOW_SCORE  = 4'b0111;
  parameter A_SHOOT     = 4'b1000;
  parameter B_SHOOT     = 4'b1001;
  parameter A_SINK      = 4'b1010;
  parameter B_SINK      = 4'b1011;
  parameter A_WIN       = 4'b1100;
  parameter B_WIN       = 4'b1101;

 
  parameter A_ROUND_WIN = 4'b1110;  
  parameter B_ROUND_WIN = 4'b1111;  

  // ----------------------------------------------------------------
  // SSD definitions
  // ----------------------------------------------------------------
  parameter SSD_0     = 8'b00111111; // '0'
  parameter SSD_1     = 8'b00000110; // '1'
  parameter SSD_2     = 8'b01011011; // '2'
  parameter SSD_3     = 8'b01001111; // '3'
  parameter SSD_4     = 8'b01100110; // '4'
  parameter SSD_5     = 8'b01101101; // '5'
  parameter SSD_6     = 8'b01111101; // '6'
  parameter SSD_7     = 8'b00000111; // '7'
  parameter SSD_8     = 8'b01111111; // '8'
  parameter SSD_9     = 8'b01101111; // '9'
  parameter SSD_b     = 8'b01111100; // 'b'
  parameter SSD_A     = 8'b01110111; // 'A'
  parameter SSD_D     = 8'b01011110; // 'D'
  parameter SSD_I     = 8'b00000110; // 'I'
  parameter SSD_L     = 8'b00111000; // 'L'
  parameter SSD_E     = 8'b01111001; // 'E'
  parameter SSD_r     = 8'b01010000; // 'r'
  parameter SSD_o     = 8'b01011100; // 'o'
  parameter SSD_LINE  = 8'b01000000; // '-'
  parameter SSD_BLANK = 8'b00000000; // blank

  // ----------------------------------------------------------------
  // LED patterns
  // ----------------------------------------------------------------
  parameter LED_IDLE  = 8'b10011001; // Example
  parameter LED_OFF   = 8'b00000000; // All off

  // ----------------------------------------------------------------
  // Other parameters
  // ----------------------------------------------------------------
  parameter timer_limit = 50;

  // ----------------------------------------------------------------
  // Registers
  // ----------------------------------------------------------------
  reg [3:0]  state;
  reg [15:0] mapA, mapB;      
  reg [3:0]  Score_A, Score_B;
  reg [31:0] timer;
  reg [3:0]  input_count;
  reg [3:0]  input_countB;
  reg        Z; // indicates a hit

  
  reg [1:0] roundWinsA;   
  reg [1:0] roundWinsB;   
  reg       next_starter; 

  // ----------------------------------------------------------------
  // 1) SEQUENTIAL ALWAYS BLOCK
  // ----------------------------------------------------------------
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      // Synchronous reset of all regs
      state        <= IDLE;
      mapA         <= 16'b0;
      mapB         <= 16'b0;
      Score_A      <= 4'b0;
      Score_B      <= 4'b0;
      timer        <= 32'b0;
      input_count  <= 4'b0;
      input_countB <= 4'b0;
      Z            <= 1'b0;
      // NEW:
      roundWinsA   <= 2'b00;
      roundWinsB   <= 2'b00;
      next_starter <= 1'b0;  
    end 
    else begin
      
      case (state)

        // ----------------------------------------------------------
        IDLE: begin
          if (start) begin
            state <= SHOW_A;  // A starts by default in round 1
          end
        end

        // ----------------------------------------------------------
        SHOW_A: begin
          if (timer < timer_limit) begin
            timer <= timer + 1;
            state <= SHOW_A;
          end 
          else begin
            timer <= 0;
            state <= A_IN;
          end
        end

        // ----------------------------------------------------------
        A_IN: begin
          if (pAb == 0) begin
            // Wait for press
            state <= A_IN;
          end 
          else begin
            // Press recognized
            if (mapA[{X, Y}] == 1) begin
              state <= ERROR_A;
            end 
            else begin
              mapA[{X, Y}] <= 1'b1;
              if (input_count >= 2) begin
                input_count <= 0;
                if(next_starter == 0 )
                  state       <= SHOW_B;
                else 
                  state <= SHOW_SCORE;
              end 
              else begin
                input_count <= input_count + 1;
                state       <= A_IN;
              end
            end
          end
        end

        // ----------------------------------------------------------
        ERROR_A: begin
          if (timer < timer_limit) begin
            timer <= timer + 1;
            state<= ERROR_A;
          end 
          else begin
            timer <= 0;
            state <= A_IN;
          end
        end

        // ----------------------------------------------------------
        SHOW_B: begin
          if (timer < timer_limit) begin
            timer <= timer + 1;
            state <= SHOW_B;
          end 
          else begin
            timer <= 0;
            state <= B_IN;
          end
        end

        // ----------------------------------------------------------
        B_IN: begin
          if (pBb == 0) begin
            state <= B_IN;
          end 
          else begin
            if (mapB[{X, Y}] == 1) begin
              state <= ERROR_B;
            end 
            else begin
              mapB[{X, Y}] <= 1'b1;
              if (input_countB >= 2) begin
                input_countB <= 0;
                if(next_starter == 0)
                  state        <= SHOW_SCORE;
                else
                  state <= SHOW_A;
              end 
              else begin
                input_countB <= input_countB + 1;
                state        <= B_IN;
              end
            end
          end
        end

        // ----------------------------------------------------------
        ERROR_B: begin
          if (timer < timer_limit) begin
            timer <= timer + 1;
            state <=ERROR_B;
          end 
          else begin
            timer <= 0;
            state <= B_IN;
          end
        end

        // ----------------------------------------------------------
        SHOW_SCORE: begin
          if (timer < timer_limit) begin
            timer <= timer + 1;
            state<= SHOW_SCORE;
          end 
          else begin
            timer <= 0;
            if(next_starter == 0)
              state <= A_SHOOT;  // A shoots first by default
            else
              state <= B_SHOOT;
          end
        end

        // ----------------------------------------------------------
        A_SHOOT: begin
          if (pAb == 0) begin
            state <= A_SHOOT;
          end 
          else begin
            // Shoot
            if (mapB[{X, Y}] == 1) begin
              Score_A       <= Score_A + 1;
              Z             <= 1;
              mapB[{X, Y}]  <= 0;
              state         <= A_SINK;
            end 
            else begin
              Z     <= 0;
              state <= A_SINK;
            end
          end
        end

        // ----------------------------------------------------------
        A_SINK: begin
          if (timer < timer_limit) begin
            timer <= timer + 1;
            state <= A_SINK;
          end 
          else begin
            timer <= 0;
            
            if (Score_A > 3) begin
              state <= A_ROUND_WIN;  // <--- NEW
            end 
            else begin
              state <= B_SHOOT;
            end
          end
        end

        // ----------------------------------------------------------
        B_SHOOT: begin
          if (pBb == 0) begin
            state <= B_SHOOT;
          end 
          else begin
            if (mapA[{X, Y}] == 1) begin
              Score_B      <= Score_B + 1;
              Z            <= 1;
              mapA[{X, Y}] <= 0;
              state        <= B_SINK;
            end 
            else begin
              Z     <= 0;
              state <= B_SINK;
            end
          end
        end

        // ----------------------------------------------------------
        B_SINK: begin
          if (timer < timer_limit) begin
            timer <= timer + 1;
            state <= B_SINK;
          end 
          else begin
            timer <= 0;
            
            if (Score_B > 3) begin
              state <= B_ROUND_WIN; // <--- NEW
            end 
            else begin
              state <= A_SHOOT;
            end
          end
        end

        
        A_ROUND_WIN: begin
          if (timer < timer_limit) begin
            timer <= timer + 1;
            
          end
          else begin
            next_starter = 0;
            timer <= 0;
            roundWinsA <= roundWinsA + 1;
            
            if (roundWinsA == 2'b01) begin
              state <= A_WIN;
            end
            else begin
              
              next_starter <= 1'b0;  
              mapA         <= 16'b0;
              mapB         <= 16'b0;
              Score_A      <= 4'b0;
              Score_B      <= 4'b0;
              Z            <= 1'b0;
              input_count  <= 4'b0;
              input_countB <= 4'b0;
              state <= SHOW_A;
            end
          end
        end

        
        B_ROUND_WIN: begin
          if (timer < timer_limit) begin
            timer <= timer + 1;
          end
          else begin
            next_starter = 1;
            timer <= 0;
            roundWinsB <= roundWinsB + 1;
            
            if (roundWinsB == 2'b01) begin
              state <= B_WIN;
            end
            else begin
              
              next_starter <= 1'b1;

              // reset for next round
              mapA         <= 16'b0;
              mapB         <= 16'b0;
              Score_A      <= 4'b0;
              Score_B      <= 4'b0;
              Z            <= 1'b0;
              input_count  <= 4'b0;
              input_countB <= 4'b0;

              // B starts => go to SHOW_B
              state <= SHOW_B;
            end
          end
        end

        // ----------------------------------------------------------
        A_WIN: begin
          
          if (timer < timer_limit) begin
            timer <= timer + 1;
          end 
          else begin
            timer <= 0;
            
          end
        end

        // ----------------------------------------------------------
        B_WIN: begin
          // Player B is overall champion.
          if (timer < timer_limit) begin
            timer <= timer + 1;
          end 
          else begin
            timer <= 0;
            
          end
        end

        // ----------------------------------------------------------
        default: begin
          state <= IDLE;
        end

      endcase
    end
  end

  // ----------------------------------------------------------------
  // 2) COMBINATIONAL ALWAYS BLOCK
  // ----------------------------------------------------------------
  always @(*) begin

    disp3 = SSD_BLANK;
    disp2 = SSD_BLANK;
    disp1 = SSD_BLANK;
    disp0 = SSD_BLANK;
    led   = LED_OFF;

    case (state)

      // ------------------------------------------------------------
      IDLE: begin
        disp3 = SSD_I;
        disp2 = SSD_D;
        disp1 = SSD_L;
        disp0 = SSD_E;
        led   = LED_IDLE;
      end

      // ------------------------------------------------------------
      SHOW_A: begin
        disp3 = SSD_A;
        disp2 = SSD_BLANK;
        disp1 = SSD_BLANK;
        disp0 = SSD_BLANK;
        led   = LED_IDLE;
      end

      // ------------------------------------------------------------
      A_IN: begin
        disp2 = SSD_BLANK;
        disp3 = SSD_BLANK;
        // Show X
        if (X == 2'b00) disp1 = SSD_0;
        else if (X == 2'b01) disp1 = SSD_1;
        else if (X == 2'b10) disp1 = SSD_2;
        else                 disp1 = SSD_3;

        // Show Y
        if (Y == 2'b00) disp0 = SSD_0;
        else if (Y == 2'b01) disp0 = SSD_1;
        else if (Y == 2'b10) disp0 = SSD_2;
        else                 disp0 = SSD_3;

      
        if(input_count==4'b0000)        led = 8'b10000000;
        else if(input_count==4'b0001)   led = 8'b10010000;
        else if(input_count==4'b0011)   led = 8'b10110000;
        else                            led = 8'b10100000;
      end

      // ------------------------------------------------------------
      ERROR_A: begin
        disp3 = SSD_E;
        disp2 = SSD_r;
        disp1 = SSD_r;
        disp0 = SSD_o;
        led   = LED_IDLE;
      end

      // ------------------------------------------------------------
      SHOW_B: begin
        disp2 = SSD_BLANK;
        disp1 = SSD_BLANK;
        disp0 = SSD_BLANK;
        disp3 = SSD_b;
        led   = LED_IDLE;
      end

      // ------------------------------------------------------------
      B_IN: begin
        // Show X
        if (X == 2'b00) disp1 = SSD_0;
        else if (X == 2'b01) disp1 = SSD_1;
        else if (X == 2'b10) disp1 = SSD_2;
        else                 disp1 = SSD_3;

        // Show Y
        if (Y == 2'b00) disp0 = SSD_0;
        else if (Y == 2'b01) disp0 = SSD_1;
        else if (Y == 2'b10) disp0 = SSD_2;
        else                 disp0 = SSD_3;

        // LED patterns for input_countB
        if      (input_countB==4'b0000) led = 8'b00110001;
        else if (input_countB==4'b0001) led = 8'b00110101;
        else if (input_countB==4'b0011) led = 8'b00111101;
        else                            led = 8'b00111001;
      end

      // ------------------------------------------------------------
      ERROR_B: begin
        disp3 = SSD_E;
        disp2 = SSD_r;
        disp1 = SSD_r;
        disp0 = SSD_o;
        led   = LED_IDLE;
      end

      // ------------------------------------------------------------
      SHOW_SCORE: begin
        disp3 = SSD_BLANK;
        disp2 = SSD_0;
        disp1 = SSD_LINE;
        disp0 = SSD_0;
        led   = LED_IDLE;
      end

      // ------------------------------------------------------------
      A_SHOOT: begin
        disp2 = SSD_BLANK;
        disp3 = SSD_BLANK;
        
        // Show X
        if (X == 2'b00) disp1 = SSD_0;
        else if (X == 2'b01) disp1 = SSD_1;
        else if (X == 2'b10) disp1 = SSD_2;
        else                 disp1 = SSD_3;

        // Show Y
        if (Y == 2'b00) disp0 = SSD_0;
        else if (Y == 2'b01) disp0 = SSD_1;
        else if (Y == 2'b10) disp0 = SSD_2;
        else                 disp0 = SSD_3;

        if      (Score_A==0 && Score_B==0) led=8'b10000000;
        else if (Score_A==0 && Score_B==1) led=8'b10000100;
        else if (Score_A==0 && Score_B==2) led=8'b10001000;
        else if (Score_A==0 && Score_B==3) led=8'b10001100;
        else if (Score_A==1 && Score_B==0) led=8'b10010000;
        else if (Score_A==1 && Score_B==1) led=8'b10010100;
        else if (Score_A==1 && Score_B==2) led=8'b10011000;
        else if (Score_A==1 && Score_B==3) led=8'b10011100;
        else if (Score_A==2 && Score_B==0) led=8'b10100000;
        else if (Score_A==2 && Score_B==1) led=8'b10100100;
        else if (Score_A==2 && Score_B==2) led=8'b10101000;
        else if (Score_A==2 && Score_B==3) led=8'b10101100;
        else if (Score_A==3 && Score_B==0) led=8'b10110000;
        else if (Score_A==3 && Score_B==1) led=8'b10110100;
        else if (Score_A==3 && Score_B==2) led=8'b10111000;
        else if (Score_A==3 && Score_B==3) led=8'b10111100;
      end

      // ------------------------------------------------------------
      A_SINK: begin
        // Show scoreboard on disp
        if (Score_A==0 && Score_B==0) begin
          disp3 = SSD_BLANK; disp2 = SSD_0; disp1 = SSD_LINE; disp0 = SSD_0;
        end else if (Score_A==0 && Score_B==1) begin
          disp3 = SSD_BLANK; disp2 = SSD_0; disp1 = SSD_LINE; disp0 = SSD_1;
        end else if (Score_A==0 && Score_B==2) begin
          disp3 = SSD_BLANK; disp2 = SSD_0; disp1 = SSD_LINE; disp0 = SSD_2;
        end else if (Score_A==0 && Score_B==3) begin
          disp3 = SSD_BLANK; disp2 = SSD_0; disp1 = SSD_LINE; disp0 = SSD_3;
        end else if (Score_A==1 && Score_B==0) begin
          disp3 = SSD_BLANK; disp2 = SSD_1; disp1 = SSD_LINE; disp0 = SSD_0;
        end else if (Score_A==1 && Score_B==1) begin
          disp3 = SSD_BLANK; disp2 = SSD_1; disp1 = SSD_LINE; disp0 = SSD_1;
        end else if (Score_A==1 && Score_B==2) begin
          disp3 = SSD_BLANK; disp2 = SSD_1; disp1 = SSD_LINE; disp0 = SSD_2;
        end else if (Score_A==1 && Score_B==3) begin
          disp3 = SSD_BLANK; disp2 = SSD_1; disp1 = SSD_LINE; disp0 = SSD_3;
        end else if (Score_A==2 && Score_B==0) begin
          disp3 = SSD_BLANK; disp2 = SSD_2; disp1 = SSD_LINE; disp0 = SSD_0;
        end else if (Score_A==2 && Score_B==1) begin
          disp3 = SSD_BLANK; disp2 = SSD_2; disp1 = SSD_LINE; disp0 = SSD_1;
        end else if (Score_A==2 && Score_B==2) begin
          disp3 = SSD_BLANK; disp2 = SSD_2; disp1 = SSD_LINE; disp0 = SSD_2;
        end else if (Score_A==2 && Score_B==3) begin
          disp3 = SSD_BLANK; disp2 = SSD_2; disp1 = SSD_LINE; disp0 = SSD_3;
        end else if (Score_A==3 && Score_B==0) begin
          disp3 = SSD_BLANK; disp2 = SSD_3; disp1 = SSD_LINE; disp0 = SSD_0;
        end else if (Score_A==3 && Score_B==1) begin
          disp3 = SSD_BLANK; disp2 = SSD_3; disp1 = SSD_LINE; disp0 = SSD_1;
        end else if (Score_A==3 && Score_B==2) begin
          disp3 = SSD_BLANK; disp2 = SSD_3; disp1 = SSD_LINE; disp0 = SSD_2;
        end else if (Score_A==3 && Score_B==3) begin
          disp3 = SSD_BLANK; disp2 = SSD_3; disp1 = SSD_LINE; disp0 = SSD_3;
        end else if (Score_A==4 && Score_B==0) begin
          disp3 = SSD_BLANK; disp2 = SSD_4; disp1 = SSD_LINE; disp0 = SSD_0;
        end else if (Score_A==4 && Score_B==1) begin
          disp3 = SSD_BLANK; disp2 = SSD_4; disp1 = SSD_LINE; disp0 = SSD_1;
        end else if (Score_A==4 && Score_B==2) begin
          disp3 = SSD_BLANK; disp2 = SSD_4; disp1 = SSD_LINE; disp0 = SSD_2;
        end else if (Score_A==4 && Score_B==3) begin
          disp3 = SSD_BLANK; disp2 = SSD_4; disp1 = SSD_LINE; disp0 = SSD_3;
        end

        // Flash LED if Z=1
        if (timer < timer_limit) begin
          if (Z == 1) led = 8'b11111111;
          else        led = 8'b00000000;
        end 
        else begin
          led = 8'b00000000;
        end
      end

      // ------------------------------------------------------------
      B_SHOOT: begin
        disp2 = SSD_BLANK;
        disp3 = SSD_BLANK;
        // Show X
        if (X == 2'b00) disp1 = SSD_0;
        else if (X == 2'b01) disp1 = SSD_1;
        else if (X == 2'b10) disp1 = SSD_2;
        else                 disp1 = SSD_3;

        // Show Y
        if (Y == 2'b00) disp0 = SSD_0;
        else if (Y == 2'b01) disp0 = SSD_1;
        else if (Y == 2'b10) disp0 = SSD_2;
        else                 disp0 = SSD_3;

        // LED scoreboard
        if      (Score_A==0 && Score_B==0) led=8'b00000001;
        else if (Score_A==0 && Score_B==1) led=8'b00000101;
        else if (Score_A==0 && Score_B==2) led=8'b00001001;
        else if (Score_A==0 && Score_B==3) led=8'b00001101;
        else if (Score_A==1 && Score_B==0) led=8'b00010001;
        else if (Score_A==1 && Score_B==1) led=8'b00010101;
        else if (Score_A==1 && Score_B==2) led=8'b00011001;
        else if (Score_A==1 && Score_B==3) led=8'b00011101;
        else if (Score_A==2 && Score_B==0) led=8'b00100001;
        else if (Score_A==2 && Score_B==1) led=8'b00100101;
        else if (Score_A==2 && Score_B==2) led=8'b00101001;
        else if (Score_A==2 && Score_B==3) led=8'b00101101;
        else if (Score_A==3 && Score_B==0) led=8'b00110001;
        else if (Score_A==3 && Score_B==1) led=8'b00110101;
        else if (Score_A==3 && Score_B==2) led=8'b00111001;
        else if (Score_A==3 && Score_B==3) led=8'b00111101;
      end

      // ------------------------------------------------------------
      B_SINK: begin
        if (Score_A==0 && Score_B==0) begin
          disp3=SSD_BLANK; disp2=SSD_0; disp1=SSD_LINE; disp0=SSD_0;
        end else if (Score_A==0 && Score_B==1) begin
          disp3=SSD_BLANK; disp2=SSD_0; disp1=SSD_LINE; disp0=SSD_1;
        end else if (Score_A==0 && Score_B==2) begin
          disp3=SSD_BLANK; disp2=SSD_0; disp1=SSD_LINE; disp0=SSD_2;
        end else if (Score_A==0 && Score_B==3) begin
          disp3=SSD_BLANK; disp2=SSD_0; disp1=SSD_LINE; disp0=SSD_3;
        end else if (Score_A==1 && Score_B==0) begin
          disp3=SSD_BLANK; disp2=SSD_1; disp1=SSD_LINE; disp0=SSD_0;
        end else if (Score_A==1 && Score_B==1) begin
          disp3=SSD_BLANK; disp2=SSD_1; disp1=SSD_LINE; disp0=SSD_1;
        end else if (Score_A==1 && Score_B==2) begin
          disp3=SSD_BLANK; disp2=SSD_1; disp1=SSD_LINE; disp0=SSD_2;
        end else if (Score_A==1 && Score_B==3) begin
          disp3=SSD_BLANK; disp2=SSD_1; disp1=SSD_LINE; disp0=SSD_3;
        end else if (Score_A==2 && Score_B==0) begin
          disp3=SSD_BLANK; disp2=SSD_2; disp1=SSD_LINE; disp0=SSD_0;
        end else if (Score_A==2 && Score_B==1) begin
          disp3=SSD_BLANK; disp2=SSD_2; disp1=SSD_LINE; disp0=SSD_1;
        end else if (Score_A==2 && Score_B==2) begin
          disp3=SSD_BLANK; disp2=SSD_2; disp1=SSD_LINE; disp0=SSD_2;
        end else if (Score_A==2 && Score_B==3) begin
          disp3=SSD_BLANK; disp2=SSD_2; disp1=SSD_LINE; disp0=SSD_3;
        end else if (Score_A==3 && Score_B==0) begin
          disp3=SSD_BLANK; disp2=SSD_3; disp1=SSD_LINE; disp0=SSD_0;
        end else if (Score_A==3 && Score_B==1) begin
          disp3=SSD_BLANK; disp2=SSD_3; disp1=SSD_LINE; disp0=SSD_1;
        end else if (Score_A==3 && Score_B==2) begin
          disp3=SSD_BLANK; disp2=SSD_3; disp1=SSD_LINE; disp0=SSD_2;
        end else if (Score_A==3 && Score_B==3) begin
          disp3=SSD_BLANK; disp2=SSD_3; disp1=SSD_LINE; disp0=SSD_3;
        end else if (Score_A==0 && Score_B==4) begin
          disp3=SSD_BLANK; disp2=SSD_0; disp1=SSD_LINE; disp0=SSD_4;
        end else if (Score_A==1 && Score_B==4) begin
          disp3=SSD_BLANK; disp2=SSD_1; disp1=SSD_LINE; disp0=SSD_4;
        end else if (Score_A==2 && Score_B==4) begin
          disp3=SSD_BLANK; disp2=SSD_2; disp1=SSD_LINE; disp0=SSD_4;
        end else if (Score_A==3 && Score_B==4) begin
          disp3=SSD_BLANK; disp2=SSD_3; disp1=SSD_LINE; disp0=SSD_4;
        end

        // Flash LED on hit
        if (timer < timer_limit) begin
          if (Z == 1) led = 8'b11111111;
          else        led = 8'b00000000;
        end 
        else begin
          led = 8'b00000000;
        end
      end

      
      A_ROUND_WIN: begin
        // Keep A on the leftmost digit
        disp3 = SSD_A;
        
      
        
        if (roundWinsA == 2'b00) begin
          disp2 = SSD_1;
        end else if (roundWinsA == 2'b01) begin
          disp2 = SSD_2;
        end else begin
          disp2 = SSD_2;  // 2'b10 => "2"
        end
      
        // ----- disp1 = '-' -----
        disp1 = SSD_LINE;
      
        // ----- disp0 = roundWinsB -----
        if (roundWinsB == 2'b00) begin
          disp0 = SSD_0;
        end else if (roundWinsB == 2'b01) begin
          disp0 = SSD_1;
        end else begin
          disp0 = SSD_2;
        end
      
        
        led = 8'b11111111;
      end

      B_ROUND_WIN: begin
        
        // Keep b on the leftmost digit
        disp3 = SSD_b;
        
        if (roundWinsB == 2'b00) begin
          disp0 = SSD_1;
        end else if (roundWinsB == 2'b01) begin
          disp0 = SSD_2;
        end else begin
          disp0 = SSD_2;  // 2'b10 => "2"
        end
      
        disp1 = SSD_LINE;
      
        if (roundWinsA == 2'b00) begin
          disp2 = SSD_0;
        end else if (roundWinsA == 2'b01) begin
          disp2 = SSD_1;
        end else begin
          disp2 = SSD_2;
        end
      
        led = 8'b11111111;
      end

      // ------------------------------------------------------------
      A_WIN: begin
        disp3 = SSD_A;
        if (roundWinsA == 2 && roundWinsB == 0) begin
          // "2-0"
          disp2 = SSD_2;  
          disp1 = SSD_LINE;
          disp0 = SSD_0;
        end 
        else if (roundWinsA == 2 && roundWinsB == 1) begin
          // "2-1"
          disp2 = SSD_2;
          disp1 = SSD_LINE;
          disp0 = SSD_1;
        end
        if (timer < (timer_limit - 40)) begin
          led = 8'b10000001;
        end else if (timer < (timer_limit - 30)) begin
          led = 8'b11000011;
        end else if (timer < (timer_limit - 20)) begin
          led = 8'b11100111;
        end else if (timer < (timer_limit - 10)) begin
          led = 8'b01111110;
        end else if (timer < timer_limit) begin
          led = 8'b00111100;
        end else begin
          led = 8'b00011000;
        end
      end

      // ------------------------------------------------------------
      B_WIN: begin
        disp3 = SSD_b;
        if (roundWinsB == 2 && roundWinsA == 0) begin
          // "0-2"
          disp2 = SSD_0;  
          disp1 = SSD_LINE;
          disp0 = SSD_2;
        end 
        else if (roundWinsB == 2 && roundWinsA == 1) begin
          // "1-2"
          disp2 = SSD_1;
          disp1 = SSD_LINE;
          disp0 = SSD_2;
        end
         
        if (timer < (timer_limit - 40)) begin
          led = 8'b10000001;
        end else if (timer < (timer_limit - 30)) begin
          led = 8'b11000011;
        end else if (timer < (timer_limit - 20)) begin
          led = 8'b11100111;
        end else if (timer < (timer_limit - 10)) begin
          led = 8'b01111110;
        end else if (timer < timer_limit) begin
          led = 8'b00111100;
        end else begin
          led = 8'b00011000;
        end
      end

      // ------------------------------------------------------------
      default: begin
        disp3 = SSD_BLANK;
        disp2 = SSD_BLANK;
        disp1 = SSD_BLANK;
        disp0 = SSD_BLANK;
        led   = LED_OFF;
      end

    endcase
  end

endmodule