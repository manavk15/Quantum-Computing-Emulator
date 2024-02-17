

`include "defines.vh"
module DW_fp_mac_inst #(
  parameter inst_sig_width = 52,
  parameter inst_exp_width = 11,
  parameter inst_ieee_compliance = 1 // These need to be fixed to decrease error
) ( 
  input wire [inst_sig_width+inst_exp_width : 0] inst_a,
  input wire [inst_sig_width+inst_exp_width : 0] inst_b,
  input wire [inst_sig_width+inst_exp_width : 0] inst_c,
  input wire [2 : 0] inst_rnd,
  output wire [inst_sig_width+inst_exp_width : 0] z_inst,
  output wire [7 : 0] status_inst
);

  // Instance of DW_fp_mac
  DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 (
    .a(inst_a),
    .b(inst_b),
    .c(inst_c),
    .rnd(inst_rnd),
    .z(z_inst),
    .status(status_inst) 
  );
endmodule

// module DW_fp_add_inst #(
//   parameter sig_width = 52,
//   parameter exp_width = 11,
//   parameter ieee_compliance = 1 // These need to be fixed to decrease error
// ) ( 
//   input wire [sig_width+exp_width : 0] a,
//   input wire [sig_width+exp_width : 0] b,
//   // input wire [inst_sig_width+inst_exp_width : 0] c,
//   input wire [2 : 0] rnd,
//   output wire [sig_width+exp_width : 0] z,
//   output wire [7 : 0] status_inst
// );

  // Instance of DW_fp_add
//   DW_fp_add  #(
// 				.sig_width        (23),
// 				.exp_width        (8),
// 				.ieee_compliance  (3)
// 			) fp_add_mod (
// 				.a                (a), 
// 				.b                (b), 
// 				.rnd              (rnd), 
// 				.z                (z), 
// 				.status           (status));
// endmodule 


//---------------------------------------------------------------------------
// DUT 
//---------------------------------------------------------------------------
module MyDesign(
//---------------------------------------------------------------------------
//System signals
  input wire reset_n                      ,  
  input wire clk                          ,

//---------------------------------------------------------------------------
//Control signals
  input wire dut_valid                    , 
  output wire dut_ready                   ,

//---------------------------------------------------------------------------
//q_state_input SRAM interface
  output wire                                               q_state_input_sram_write_enable  ,
  output wire [`Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_input_sram_write_address ,
  output wire [`Q_STATE_INPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_input_sram_write_data    ,
  output wire [`Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_input_sram_read_address  , 
  input  wire [`Q_STATE_INPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_input_sram_read_data     ,

//---------------------------------------------------------------------------
//q_state_output SRAM interface
  output wire                                                q_state_output_sram_write_enable  ,
  output wire [`Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_output_sram_write_address ,
  output wire [`Q_STATE_OUTPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_output_sram_write_data    ,
  output wire [`Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_output_sram_read_address  , 
  input  wire [`Q_STATE_OUTPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_output_sram_read_data     ,

//---------------------------------------------------------------------------
//scratchpad SRAM interface                                                       
  output wire                                                scratchpad_sram_write_enable        ,
  output wire [`SCRATCHPAD_SRAM_ADDRESS_UPPER_BOUND-1:0]     scratchpad_sram_write_address       ,
  output wire [`SCRATCHPAD_SRAM_DATA_UPPER_BOUND-1:0]        scratchpad_sram_write_data          ,
  output wire [`SCRATCHPAD_SRAM_ADDRESS_UPPER_BOUND-1:0]     scratchpad_sram_read_address        , 
  input  wire [`SCRATCHPAD_SRAM_DATA_UPPER_BOUND-1:0]        scratchpad_sram_read_data           ,

//---------------------------------------------------------------------------
//q_gates SRAM interface                                                       
  output wire                                                q_gates_sram_write_enable           ,
  output wire [`Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0]        q_gates_sram_write_address          ,
  output wire [`Q_GATES_SRAM_DATA_UPPER_BOUND-1:0]           q_gates_sram_write_data             ,
  output wire [`Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0]        q_gates_sram_read_address           ,  
  input  wire [`Q_GATES_SRAM_DATA_UPPER_BOUND-1:0]           q_gates_sram_read_data              
);

  localparam inst_sig_width = 52;
  localparam inst_exp_width = 11;
  localparam inst_ieee_compliance = 1;

  //control lines
  reg [1:0] SI_read_addr_sel;
  reg [1:0] rowcount_sel;
  reg [1:0] qgates_read_addr_sel;
  reg [1:0] element_count_sel;
  reg [1:0] matrix_count_sel;
  reg [1:0] mux_sel;
  reg [1:0] mac_sel;
  reg [1:0] scratchpad_sram_write_addr_sel;
  reg [1:0] output_sram_write_addr_sel;
  reg [1:0] scratchpad_sram_read_addr_sel;
  reg [1:0] addr_tracker_sel;
  reg [31:0] q;
  reg [31:0] m;
  reg [3:0]		current_state;
  reg [3:0]		next_state;

  reg [31:0]rowcount;
  reg [31:0]matrix_count;
  reg [31:0]element_count;
  reg compute_complete;
  reg dut_ready_r;

  reg[32:0] temp_addr;
  wire[63:0] temp;
  assign temp = 64'h3ff0000000000000;
  reg  [inst_sig_width+inst_exp_width : 0] inst_c_r;
  reg  [inst_sig_width+inst_exp_width : 0] inst_c2_r;
  wire [inst_sig_width+inst_exp_width : 0] z_inst;
  wire [inst_sig_width+inst_exp_width : 0] z_inst4;
  wire [63:0] temp1;
  wire [inst_sig_width+inst_exp_width : 0] z_inst2;
  wire [inst_sig_width+inst_exp_width : 0] z_inst3;
  wire [63:0] temp2;

  // wire  [inst_sig_width+inst_exp_width : 0] a;
   wire  [inst_sig_width+inst_exp_width : 0] b;
  // // wire  [inst_sig_width+inst_exp_width : 0] c;
  // wire  [2 : 0] rnd;
  // wire  [inst_sig_width+inst_exp_width : 0] z;
  // wire  [7 : 0] status;

  wire  [inst_sig_width+inst_exp_width : 0] inst_a;
  wire  [inst_sig_width+inst_exp_width : 0] inst_b;
  wire  [inst_sig_width+inst_exp_width : 0] inst_c;
  wire  [2 : 0] inst_rnd;
  
  wire [7 : 0] status_inst;


  wire  [inst_sig_width+inst_exp_width : 0] inst_a2;
  wire  [inst_sig_width+inst_exp_width : 0] inst_b2;
  wire  [inst_sig_width+inst_exp_width : 0] inst_c2;
  // wire [inst_sig_width+inst_exp_width : 0] z_inst2;

  wire  [inst_sig_width+inst_exp_width : 0] inst_a3;
  wire  [inst_sig_width+inst_exp_width : 0] inst_b3;
  wire  [inst_sig_width+inst_exp_width : 0] inst_c3;
  // wire [inst_sig_width+inst_exp_width : 0] z_inst3;

  wire  [inst_sig_width+inst_exp_width : 0] inst_a4;
  wire  [inst_sig_width+inst_exp_width : 0] inst_b4;
  wire  [inst_sig_width+inst_exp_width : 0] inst_c4;
  



  reg  [inst_sig_width+inst_exp_width : 0] inst_a_r;
  reg  [inst_sig_width+inst_exp_width : 0] inst_b_r;

  // reg  [2 : 0] inst_rnd;
  reg [inst_sig_width+inst_exp_width : 0] z_inst_r;

  // reg [7 : 0] status_inst;

  reg  [inst_sig_width+inst_exp_width : 0] inst_a2_r;
  reg  [inst_sig_width+inst_exp_width : 0] inst_b2_r;

  reg [inst_sig_width+inst_exp_width : 0] z_inst2_r;

  reg  [inst_sig_width+inst_exp_width : 0] inst_a3_r;
  reg  [inst_sig_width+inst_exp_width : 0] inst_b3_r;
  reg  [inst_sig_width+inst_exp_width : 0] inst_c3_r;
  reg [inst_sig_width+inst_exp_width : 0] z_inst3_r;

  reg  [inst_sig_width+inst_exp_width : 0] inst_a4_r;
  reg  [inst_sig_width+inst_exp_width : 0] inst_b4_r;
  reg  [inst_sig_width+inst_exp_width : 0] inst_c4_r;
  reg [inst_sig_width+inst_exp_width : 0] z_inst4_r;

  // wire[63:0] temp;
  // assign temp = 64'h3ff0000000000000;
  // wire [inst_sig_width+inst_exp_width : 0] z_inst;
  // wire [inst_sig_width+inst_exp_width : 0] z_inst4;
  // wire [63:0] temp1;
  // wire [inst_sig_width+inst_exp_width : 0] z_inst2;
  // wire [inst_sig_width+inst_exp_width : 0] z_inst3;
  // wire [63:0] temp2;

  // Inside the MyDesign module

  reg                                               q_state_input_sram_write_enable_r;
  reg [`Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_input_sram_write_address_r;
  reg [`Q_STATE_INPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_input_sram_write_data_r;
  reg [`Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_input_sram_read_address_r;

  reg                                                 q_gates_sram_write_enable_r;
  reg [`Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0]        q_gates_sram_write_address_r;
  reg [`Q_GATES_SRAM_DATA_UPPER_BOUND-1:0]           q_gates_sram_write_data_r;
  reg [`Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0]        q_gates_sram_read_address_r;

  reg                                                scratchpad_sram_write_enable_r        ;
  reg [`SCRATCHPAD_SRAM_ADDRESS_UPPER_BOUND-1:0]     scratchpad_sram_write_address_r       ;
  reg[32:0] address_tracker_r;
  wire[32:0] address_tracker;
  reg [`SCRATCHPAD_SRAM_DATA_UPPER_BOUND-1:0]        scratchpad_sram_write_data_r          ;
  reg [`SCRATCHPAD_SRAM_ADDRESS_UPPER_BOUND-1:0]     scratchpad_sram_read_address_r        ;

  reg                                                q_state_output_sram_write_enable_r  ;
  reg [`Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_output_sram_write_address_r ;
  reg [`Q_STATE_OUTPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_output_sram_write_data_r    ;
  reg [`Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_output_sram_read_address_r  ;

  // reg [3:0]		current_state;
  // reg [3:0]		next_state;
  //Parameters
	localparam s0   = 5'b00000;
	localparam s1   = 5'b00001;
	localparam s2   = 5'b00010;
	localparam s3   = 5'b00011;
	localparam s4   = 5'b00100;
	localparam s5   = 5'b00101;
	localparam s6   = 5'b00110;
  localparam s7   = 5'b00111;
  localparam s8   = 5'b01000;
  localparam s9   = 5'b01001;
	localparam s10  = 5'b01010;
	localparam s11  = 5'b01011;
	localparam s12  = 5'b01100;
	localparam s13  = 5'b01101;
	localparam s14  = 5'b01110;
	localparam s15  = 5'b01111;
  localparam s16  = 5'b10000;

  



always @(posedge clk or negedge reset_n) begin
		if (!reset_n) current_state <= 4'b0;
		else current_state <= next_state;
	end


	always @(*) begin
	dut_ready_r=2'b0;
	
  SI_read_addr_sel=2'b10;
  rowcount_sel=2'b10;
  qgates_read_addr_sel=2'b10;
	matrix_count_sel=2'b10;
  element_count_sel=2'b10;
  
  q_state_input_sram_write_enable_r=2'b00;
  q_gates_sram_write_enable_r=2'b00;
  scratchpad_sram_write_enable_r=2'b00;
  q_state_output_sram_write_enable_r=2'b00;

  scratchpad_sram_write_addr_sel = 2'b10;
  output_sram_write_addr_sel =2'b10;

  scratchpad_sram_read_addr_sel =2'b10;
  addr_tracker_sel =2'b00;

  mux_sel=2'b00;
  mac_sel=2'b00;

  next_state =s0;

		casex (current_state)
			s0 : begin
        SI_read_addr_sel=2'b10;
        rowcount_sel=2'b10;
        qgates_read_addr_sel=2'b10;
        element_count_sel=2'b10;
        matrix_count_sel=2'b10;
        q_state_input_sram_write_enable_r=2'b00;
				q_gates_sram_write_enable_r=2'b00;
        output_sram_write_addr_sel =2'b10;
        q_state_output_sram_write_enable_r=2'b0;
        scratchpad_sram_read_addr_sel =2'b10;
				dut_ready_r=1'b1;
				compute_complete=1'b0;
        addr_tracker_sel = 2'b00;
				if(dut_valid) next_state=s1;
				else next_state = s0;
	
			end
      s1 : begin
        SI_read_addr_sel      =2'b00;
        rowcount_sel          =2'b10;
        qgates_read_addr_sel  =2'b10;
        element_count_sel     =2'b10;        
        matrix_count_sel      =2'b10;

        dut_ready_r=1'b0;
				next_state=s2;				
			end
      s2 : begin
        SI_read_addr_sel      =2'b01;
        rowcount_sel          =2'b10;
        qgates_read_addr_sel  =2'b00;
        element_count_sel     =2'b10;        
        matrix_count_sel      =2'b10;

        dut_ready_r=1'b0;
				next_state=s3;
      end
      s3 : begin
        SI_read_addr_sel      =2'b01;
        rowcount_sel          =2'b00;
        qgates_read_addr_sel  =2'b01;
        element_count_sel     =2'b00;
        matrix_count_sel      =2'b00;

        dut_ready_r=1'b0;
				if(q_state_input_sram_read_data[127:64]==1)
        next_state=s5;
        else
        next_state=s4;
      end

      s4: begin
        SI_read_addr_sel      =2'b01;
        rowcount_sel          =2'b01;
        qgates_read_addr_sel  =2'b01;
        element_count_sel     =2'b01;
        matrix_count_sel      =2'b10;

        dut_ready_r=1'b0;
        if(rowcount==3)begin
          if(element_count==3)
            next_state=s7;
          else
            next_state=s5;
        end
        else
          next_state=s4;
        
      if(q>1)begin
        mux_sel = 2'b01;
        if(rowcount == 2**q) begin
           mac_sel = 2'b00; 
        end
        else begin
          mac_sel=2'b01;
        end


        if(rowcount == 2**q ) begin 
          if(element_count!=((2**q)**2)) begin
            if(m==1) begin
              q_state_output_sram_write_enable_r =2'b01;
              //output_sram_write_addr_sel =2'b10;
            end
            else
              scratchpad_sram_write_enable_r =2'b01;
              //scratchpad_sram_write_addr_sel=2'b10;
          end
          else begin
            if(m==1) begin
              q_state_output_sram_write_enable_r =2'b00;
              //output_sram_write_addr_sel =2'b10;
            end
            else
              scratchpad_sram_write_enable_r =2'b00;
              //scratchpad_sram_write_addr_sel=2'b10;
          end
            if(element_count + rowcount == ((2**q)**2)) begin
              addr_tracker_sel = 2'b01;
              //scratchpad_sram_write_addr_sel=2'b10;
            end
        end

      end

        end
      

      s5 : begin
        SI_read_addr_sel      =2'b11;
        rowcount_sel          =2'b01;
        qgates_read_addr_sel  =2'b01;
        element_count_sel     =2'b01;
        matrix_count_sel      =2'b10;
        if(q==1) begin
          mux_sel               =2'b01;
          mac_sel               =2'b00;
        end
        else begin
          mac_sel               =2'b01;
          mux_sel               =2'b01;

        end


        dut_ready_r=1'b0;
        

        next_state=s6;
      end
      s6 : begin
        SI_read_addr_sel      =2'b01;
        rowcount_sel          =2'b11;
        qgates_read_addr_sel  =2'b01;
        element_count_sel     =2'b01;
        matrix_count_sel      =2'b10;
        
        // if(q==1)begin
            mux_sel               =2'b01;
            mac_sel               =2'b01;
            
        // end

        dut_ready_r=1'b0;
        if(q<2)
        next_state=s7;
        // if(rowcount==3 && element_count!=3)
        else begin
          next_state=s4;
        end

        if(q==1)begin                                                   // Q=1; 
          //  addr_tracker_sel      =2'b01;
          //   mac_sel               =2'b00;
            
          //   if(m == 1)begin
          //       mux_sel=2'b01;
          //   end
          //   else
          //     if(matrix_count == m)
          //       mux_sel =2'b01;
          //     else
          //       mux_sel =2'b10;

          if(matrix_count == 1) begin                                         //At the last matrix multiplication I am writing it to the output sram hence checking the matrix count
            // q_state_output_sram_write_enable_r=2'b01;       
            output_sram_write_addr_sel =2'b00;
            
          end
          else begin
            
            // scratchpad_sram_write_enable_r =2'b01;
            if(matrix_count<m)
              scratchpad_sram_write_addr_sel = 2'b01;
            else
              scratchpad_sram_write_addr_sel = 2'b00;
          end
        end
        else 
          if(rowcount == 1 ) begin 
          if((element_count + (2**q)-1) == (2**q)**2) begin
            if(m==1) begin
              // q_state_output_sram_write_enable_r =2'b01;
              output_sram_write_addr_sel =2'b00;
            end
            else
              // scratchpad_sram_write_enable_r =2'b01;
              scratchpad_sram_write_addr_sel=2'b00;
          end
          else begin
            if(m==1) begin
              // q_state_output_sram_write_enable_r =2'b00;
              output_sram_write_addr_sel =2'b01;
            end
            else
              // scratchpad_sram_write_enable_r =2'b00;
              scratchpad_sram_write_addr_sel=2'b01;
          end
            // if(element_count + rowcount == ((2**q)**2)) begin
            //   // addr_tracker_sel = 2'b01;
            //   scratchpad_sram_write_addr_sel=2'b00;
            // end
        end
        

        // if(q>=2)begin 
          
        //       scratchpad_sram_write_enable_r =2'b01;
        //       if((element_count+2**q)-((2**q)**2) != 1)   //element_count + no. of rows  - total no. of elements should be 1 to get 0th address
        //         scratchpad_sram_write_addr_sel = 2'b01;
        //       else
        //         scratchpad_sram_write_addr_sel = 2'b00;
          
        // // else if(rowcount == 3 && element_count==3)
        // // next_state=s8;
        // // else
        // // next_state=s5;

        // end
      end
      s7 : begin
        SI_read_addr_sel      =2'b10;
        rowcount_sel          =2'b01;
        qgates_read_addr_sel  =2'b10;
        element_count_sel     =2'b01;
        matrix_count_sel      =2'b10;
        mac_sel               =2'b00;
        

        if(q==1)begin                                                   // Q=1; 
           addr_tracker_sel      =2'b01;
            mac_sel               =2'b00;
            
            if(m == 1)begin
                mux_sel=2'b01;
            end
            else
              if(matrix_count == m)
                mux_sel =2'b01;
              else
                mux_sel =2'b10;

          if(matrix_count == 1) begin                                         //At the last matrix multiplication I am writing it to the output sram hence checking the matrix count
            q_state_output_sram_write_enable_r=2'b01;       
            output_sram_write_addr_sel =2'b10;
            
          end
          else begin
            
            scratchpad_sram_write_enable_r =2'b01;
            // if(matrix_count<m)
            //   scratchpad_sram_write_addr_sel = 2'b01;
            // else
            scratchpad_sram_write_addr_sel = 2'b10;
          end
        end

        else begin
          mac_sel = 2'b01;
            if(matrix_count == m) begin
              mux_sel = 2'b01;
            end
            else begin
              mux_sel = 2'b10;
            end

        end
        dut_ready_r=1'b0;
        
        next_state=s8;

      end
      s8 : begin
        SI_read_addr_sel      =2'b10;
        rowcount_sel          =2'b01;
        qgates_read_addr_sel  =2'b10;
        element_count_sel     =2'b01;
        matrix_count_sel      =2'b01;
        
        if(q==1)begin                                                                     //FOR Q=1
            mac_sel               =2'b01;
            
            end
            if(matrix_count == 1) begin
              q_state_output_sram_write_enable_r=2'b00;
              output_sram_write_addr_sel =2'b01;
              if(m == 1)
                mux_sel               =2'b01;
              else
                mux_sel               =2'b10;
            end
            else begin
              scratchpad_sram_write_enable_r =2'b00;
              scratchpad_sram_write_addr_sel = 2'b01;
              if(matrix_count == m)
                mux_sel               =2'b01;
              else
                mux_sel               =2'b10;
            end
          if(q>1) begin
            mac_sel = 2'b01;
            if(matrix_count == m) begin
              mux_sel = 2'b01;
            end
            else begin
              mux_sel = 2'b10;
            end


            if(matrix_count == 1)
              output_sram_write_addr_sel =2'b01;
            else
              scratchpad_sram_write_addr_sel =2'b01;

        end
        dut_ready_r=1'b0;
        // if(q<2)
        // next_state = s8; 
        // else
        // next_state = s5;

        next_state = s9;
      end
      s9 : begin
        SI_read_addr_sel      =2'b10;
        rowcount_sel          =2'b10;
        qgates_read_addr_sel  =2'b10;
        element_count_sel     =2'b10;
        matrix_count_sel      =2'b10;
        mac_sel               =2'b00;
        mux_sel               =2'b00;


        if(matrix_count == 0) begin
          q_state_output_sram_write_enable_r=2'b01;
          output_sram_write_addr_sel =2'b10;
        end
        else begin
          scratchpad_sram_write_enable_r =2'b01;
          scratchpad_sram_write_addr_sel = 2'b10;
        end

        if(q>1) begin
            if(m==1) begin
              q_state_output_sram_write_enable_r =2'b01;
              output_sram_write_addr_sel =2'b10;
              end
            else
              if(matrix_count != 0) begin
                scratchpad_sram_write_enable_r =2'b01;
                scratchpad_sram_write_addr_sel=2'b10;
              end
              else begin 
                q_state_output_sram_write_enable_r =2'b01;
                output_sram_write_addr_sel =2'b10;
            end
        end

        dut_ready_r=1'b0;
        if(matrix_count==0)
        next_state =s0;
        else
        next_state = s10;
      end
      s10 : begin
        SI_read_addr_sel      =2'b10;
        rowcount_sel          =2'b10;
        qgates_read_addr_sel  =2'b01;
        element_count_sel     =2'b10;
        matrix_count_sel      =2'b10;
        scratchpad_sram_read_addr_sel =2'b00;
        dut_ready_r=1'b0;
				// if(matrix_count>1)
          next_state=s11;
        // else
        //   next_state=s0;				
			end
      s11 : begin
        SI_read_addr_sel      =2'b10;
        rowcount_sel          =2'b11;
        qgates_read_addr_sel  =2'b01;
        element_count_sel     =2'b11;
        matrix_count_sel      =2'b10;
        scratchpad_sram_read_addr_sel =2'b01;

				next_state=s12;
      end
      s12 : begin
        SI_read_addr_sel      =2'b10;
        rowcount_sel          =2'b01;
        qgates_read_addr_sel  =2'b01;
        element_count_sel     =2'b01;
        matrix_count_sel      =2'b10;
        
        mux_sel = 2'b10;
        mac_sel = 2'b00;

        if(q>1)begin
          if(rowcount == 2**q)
            mac_sel = 2'b00;
          else
            mac_sel = 2'b01;

          dut_ready_r=1'b0;
        end

        if(q<2) begin
          next_state=s13;
          scratchpad_sram_read_addr_sel =2'b00;
        end
        else begin 
          if(rowcount==2)begin
            scratchpad_sram_read_addr_sel =2'b11;
            next_state=s13;
          end
          else if(rowcount == 3 && element_count == 3)begin
            scratchpad_sram_read_addr_sel =2'b01;
            next_state=s7;
          end
          else begin
          scratchpad_sram_read_addr_sel =2'b01;
            next_state=s12;
          end
        end


        if(q>=2) begin

            if(element_count != ((2**q)**2) && rowcount == 2**q)begin
              
              if(matrix_count == 1)begin
                q_state_output_sram_write_enable_r = 2'b01;
                // if(element_count+rowcount==((2**q)**2))
                //   output_sram_write_addr_sel         = 2'b00;
                // else
                //   output_sram_write_addr_sel         =2'b01;
              end
              else begin
                scratchpad_sram_write_enable_r = 2'b01;
                // scratchpad_sram_write_addr_sel = 2'b01;
            end
            end
            else begin
                q_state_output_sram_write_enable_r = 2'b00;
                // output_sram_write_addr_sel         = 2'b10;
                scratchpad_sram_write_enable_r = 2'b00;
                // scratchpad_sram_write_addr_sel = 2'b10;
            end

            if(matrix_count == 1)
              output_sram_write_addr_sel =2'b10;
            else
              scratchpad_sram_write_addr_sel =2'b10;
            if(rowcount == 2**q) begin
              if(element_count + rowcount == ((2**q)**2))
              addr_tracker_sel = 2'b01;
            end
        end

        
      end 
      s13 : begin
        SI_read_addr_sel      =2'b10;
        rowcount_sel          =2'b11;
        qgates_read_addr_sel  =2'b01;
        element_count_sel     =2'b01;
        matrix_count_sel      =2'b10;
        scratchpad_sram_read_addr_sel =2'b01;  
        mux_sel = 2'b10;
        mac_sel = 2'b01;

        if(q==1)
        begin
          if(matrix_count==1)
            output_sram_write_addr_sel =2'b00;
          else 
            scratchpad_sram_write_addr_sel =2'b01;
        end
        dut_ready_r=1'b0;



        if(q>1) begin
          if(matrix_count == 1)
              if(element_count +(2**q) -1 == (2**q)**2)
                output_sram_write_addr_sel =2'b00;
              else
                output_sram_write_addr_sel =2'b01;
          else
            scratchpad_sram_write_addr_sel  =2'b01;
        end
        // if(rowcount==2)
        next_state = s12;
        if(q<2)
          next_state=s7;
        // if(q>=2)begin 
        //       scratchpad_sram_write_enable_r =2'b00;
        //       // if((element_count+2**q)-((2**q)**2) != 1)
        //         scratchpad_sram_write_addr_sel = 2'b10;
        //       // else
        //         // scratchpad_sram_write_addr_sel = 2'b00;
        //   end
      end
    default: next_state = s0;
    endcase
  end

assign dut_ready = dut_ready_r;
assign q_state_input_sram_read_address= q_state_input_sram_read_address_r;
assign q_state_input_sram_write_enable= q_state_input_sram_write_enable_r;
assign q_gates_sram_read_address = q_gates_sram_read_address_r;
assign q_gates_sram_write_enable = q_gates_sram_write_enable_r;

always @(posedge clk) begin
			if (SI_read_addr_sel == 2'b0)
				q_state_input_sram_read_address_r <= 12'b0;
      else if (SI_read_addr_sel == 2'b01)
				q_state_input_sram_read_address_r <= q_state_input_sram_read_address_r + 1'b1;
			else if (SI_read_addr_sel == 2'b10)
				q_state_input_sram_read_address_r <= q_state_input_sram_read_address_r;
      else if (SI_read_addr_sel == 2'b11)
        q_state_input_sram_read_address_r <= 1'b1;
	end

//Qgates input read address

always @(posedge clk) begin
			if (qgates_read_addr_sel == 2'b0)
				q_gates_sram_read_address_r <= 12'b0;
			else if (qgates_read_addr_sel == 2'b01)
				q_gates_sram_read_address_r <= q_gates_sram_read_address_r + 1'b1;
			else if (qgates_read_addr_sel == 2'b10)
				q_gates_sram_read_address_r <= q_gates_sram_read_address_r;
	end 

//rowcount 

always @(posedge clk) begin
			if (rowcount_sel == 2'b0)
        begin
        q <= q_state_input_sram_read_data[127:64];
        m <= q_state_input_sram_read_data[63:0];
        rowcount <= 2**q_state_input_sram_read_data[127:64];
        // indexa<=4'b0;
        end
			else if (rowcount_sel == 2'b01)begin

				rowcount <= rowcount - 1'b1;
      end
			else if (rowcount_sel == 2'b10)begin
				rowcount <= rowcount;
      end
      else if (rowcount_sel == 2'b11)begin
				rowcount <= 2**q;

      end
end

//matrix_count

  always @(posedge clk) begin
			if (matrix_count_sel == 2'b0)
        begin
          matrix_count <= q_state_input_sram_read_data[63:0];
        end
			else if (matrix_count_sel == 2'b01)begin
				matrix_count <= matrix_count - 1'b1;
        // indexa = indexa + 1'b1;
      end        
			else if (matrix_count_sel == 2'b10)begin
				matrix_count <= matrix_count;
    end
    
	end

//element_count
  always@(posedge clk) begin
      if(element_count_sel==2'b00)
        begin
          // q = q_state_input_sram_read_data[127:64];
          element_count <= (2**q_state_input_sram_read_data[127:64])**2;
        end
      else if(element_count_sel == 2'b01)
        element_count <= element_count-1;
      else if(element_count_sel == 2'b11)
        element_count <= (2**q)**2;
  end


assign q_state_input_sram_read_address = q_state_input_sram_read_address_r;
assign q_state_input_sram_write_enable = q_state_input_sram_write_enable_r;
// assign real_temp = q_state_input_sram_read_data[127:64];
// assign img_temp = q_state_input_sram_read_data[63:0];
// //real x real

  always@(posedge clk) begin
    // z_inst_r = z_inst;
    // z_inst2_r = z_inst2;
    inst_c_r <= temp1;
    inst_c2_r <= temp2;

  end

  always@(posedge clk) begin
    if(addr_tracker_sel == 2'b00)
      address_tracker_r = address_tracker;
    else
      address_tracker_r = scratchpad_sram_write_address;
  end
assign address_tracker = address_tracker_r;

	always @(posedge clk) begin
      //scratchpad_sram_write_address_r = 32'b0; // Fixing latch
      // if(scratchpad_sram_write_enable) begin
        case (scratchpad_sram_write_addr_sel)
        2'b00: scratchpad_sram_write_address_r = 32'b0;
        2'b01: scratchpad_sram_write_address_r = scratchpad_sram_write_address_r + 32'b1;
        default: scratchpad_sram_write_address_r = scratchpad_sram_write_address_r;
      endcase
      // end
      // else  scratchpad_sram_write_address_r = scratchpad_sram_write_address_r;
			// if (scratchpad_sram_write_addr_sel == 2'b00)
			// 	scratchpad_sram_write_address_r = 32'b0;
			// else if(scratchpad_sram_write_addr_sel == 2'b01)
			// 	scratchpad_sram_write_address_r = scratchpad_sram_write_address_r + 1'b1; 
			// else
      //   scratchpad_sram_write_address_r = scratchpad_sram_write_address_r;
	end

	always @(posedge clk) begin
			//scratchpad_sram_write_data_r = 0;
			// if(scratchpad_sram_write_enable) begin
          if (scratchpad_sram_write_addr_sel == 2'b00)
          scratchpad_sram_write_data_r = {temp1,temp2};
        else if(scratchpad_sram_write_addr_sel == 2'b01)  
          scratchpad_sram_write_data_r = {temp1,temp2};
        else
          scratchpad_sram_write_data_r = scratchpad_sram_write_data_r;
      // end
      // else scratchpad_sram_write_data_r = scratchpad_sram_write_data_r;
	end

  always @(posedge clk) begin
			
			if (scratchpad_sram_read_addr_sel == 2'b0)begin
				scratchpad_sram_read_address_r <= address_tracker;
        temp_addr <= address_tracker;
      end
      else if (scratchpad_sram_read_addr_sel == 2'b01)
				scratchpad_sram_read_address_r <= scratchpad_sram_read_address_r + 1'b1;
			else if (scratchpad_sram_read_addr_sel == 2'b10)
				scratchpad_sram_read_address_r <= scratchpad_sram_read_address_r;
      else if (scratchpad_sram_read_addr_sel == 2'b11)
        scratchpad_sram_read_address_r <= temp_addr;
	end

  // always @(posedge clk) begin
			
	// 		if (scratchpad_sram_read_addr_sel == 2'b0)
	// 			scratchpad_sram_read_data_r <= 12'b0;
  //     else if (scratchpad_sram_read_addr_sel == 2'b01)
	// 			scratchpad_sram_read_data_r <= scratchpad_sram_read_data_r + 1'b1;
	// 		else if (scratchpad_sram_read_addr_sel == 2'b10)
	// 			scratchpad_sram_read_data_r <= scratchpad_sram_read_data_r;
  //     else if (scratchpad_sram_read_addr_sel == 2'b11)
  //       scratchpad_sram_read_data_r <= 1'b1;
	// end

assign scratchpad_sram_read_address = scratchpad_sram_read_address_r;
assign scratchpad_sram_write_enable = scratchpad_sram_write_enable_r;
assign scratchpad_sram_write_address = scratchpad_sram_write_address_r;
assign scratchpad_sram_write_data = scratchpad_sram_write_data_r;


/////Q Output write enable/////


	always @(posedge clk) begin
      //q_state_output_sram_write_address_r = 32'b0; // fixing latchh
			// if(q_state_output_sram_write_enable) begin
          if (output_sram_write_addr_sel == 2'b00)
          q_state_output_sram_write_address_r = 32'b0;
        else if(output_sram_write_addr_sel == 2'b01)
          q_state_output_sram_write_address_r = q_state_output_sram_write_address_r + 1'b1;
        else
          q_state_output_sram_write_address_r = q_state_output_sram_write_address_r;
      // end
      // else q_state_output_sram_write_address_r = q_state_output_sram_write_address_r;
	end

  //Write data register
	always @(posedge clk) begin
          //q_state_output_sram_write_data_r = 128'b0; //fixing latch
				// if(q_state_output_sram_write_enable) begin
            if (output_sram_write_addr_sel == 2'b00)
            q_state_output_sram_write_data_r = {temp1,temp2};
          else if(output_sram_write_addr_sel == 2'b01)  
            q_state_output_sram_write_data_r = {temp1,temp2};
          else
            q_state_output_sram_write_data_r = q_state_output_sram_write_data_r;
        // end
        // else q_state_output_sram_write_data_r = q_state_output_sram_write_data_r;
			
	end

assign q_state_output_sram_write_enable = q_state_output_sram_write_enable_r;
assign q_state_output_sram_write_address = q_state_output_sram_write_address_r;
assign q_state_output_sram_write_data = q_state_output_sram_write_data_r;



assign inst_a = (mux_sel == 0) ? 64'b0 : 
                (mux_sel == 1) ? q_gates_sram_read_data[127:64] :
                (mux_sel == 2) ? q_gates_sram_read_data[127:64]:
                64'b0;

assign inst_b = (mux_sel == 0) ? 64'b0 : 
                (mux_sel == 1) ? q_state_input_sram_read_data[127:64] :
                (mux_sel == 2) ? scratchpad_sram_read_data[127:64] :
                64'b0; // Default value or handle other cases if needed

assign inst_c = (mac_sel == 0) ? 64'b0 : 
                (mac_sel == 1) ? inst_c_r:   
                64'b0;
// assign a = z_inst;
                


assign inst_a2 = (mux_sel == 0) ? 64'b0 : 
                (mux_sel == 1) ? q_gates_sram_read_data[63:0] :
                (mux_sel == 2) ? q_gates_sram_read_data[63:0]:
                64'b0;

assign inst_b2 = (mux_sel == 0) ? 64'b0 : 
                (mux_sel == 1) ? q_state_input_sram_read_data[63:0]:
                (mux_sel == 2) ? scratchpad_sram_read_data[63:0]:
                64'b0; // Default value or handle other cases if needed

assign inst_c2 = (mac_sel == 0) ? 64'b0 : 
                (mac_sel == 1) ? 64'b0:
                64'b0;





assign inst_c3 = (mac_sel == 0) ? 64'b0 : 
                (mac_sel == 1) ? inst_c2_r:
                64'b0;    




assign inst_c4 = (mac_sel == 0) ? 64'b0 : 
                (mac_sel == 1) ? 64'b0:
                64'b0;  

assign b = {~z_inst4[63], z_inst4[62:0]}; 


assign inst_rnd = 3'b000;



  DW_fp_mac_inst FP_MAC1 ( 
    .inst_a(inst_a),
    .inst_b(inst_b),
    .inst_c(inst_c),
    .inst_rnd(inst_rnd),
    .z_inst(z_inst),
    .status_inst(status_inst)
  );

  DW_fp_mac_inst FP_MAC2 ( 
    .inst_a(inst_a2),
    .inst_b(inst_b),
    .inst_c(inst_c2),
    .inst_rnd(inst_rnd),
    .z_inst(z_inst2),
    .status_inst(status_inst)
  );

  DW_fp_mac_inst FP_MAC3 ( 
    .inst_a(inst_a),
    .inst_b(inst_b2),
    .inst_c(inst_c3),
    .inst_rnd(inst_rnd),
    .z_inst(z_inst3),
    .status_inst(status_inst)
  );

    DW_fp_mac_inst FP_MAC4 ( 
    .inst_a(inst_a2),
    .inst_b(inst_b2),
    .inst_c(inst_c4),
    .inst_rnd(inst_rnd),
    .z_inst(z_inst4),
    .status_inst(status_inst)
  );

  DW_fp_mac_inst FP_MAC5 (            //z_inst-z_inst4
    .inst_a(z_inst),
    .inst_b(temp),
    .inst_c(b),
    .inst_rnd(inst_rnd),
    .z_inst(temp1),
    .status_inst(status_inst)
  );

  DW_fp_mac_inst FP_MAC6 ( 
    .inst_a(z_inst2),
    .inst_b(temp),
    .inst_c(z_inst3),
    .inst_rnd(inst_rnd),
    .z_inst(temp2),
    .status_inst(status_inst)
  );

  // end




  // This is test stub for passing input/outputs to a DP_fp_mac, there many
  // more DW macros that you can choose to use

  // DW_fp_mac_inst FP_MAC1 ( 
  //   inst_a,
  //   inst_b,
  //   inst_c,
  //   inst_rnd,
  //   z_inst,
  //   status_inst
  // );

endmodule



