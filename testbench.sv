`include "sram.sv"
`include "defines.vh"
module tb_top();


  parameter CLK_PHASE=5;
  parameter ADDR_464=12'h000;
  parameter MAX_ROUNDS=200;

  //time computeCycle[rounds];
  time computeCycle;
  //event computeStart[rounds];
  event computeStart;
  //event computeEnd[rounds];
  event computeEnd;
  //event checkFinish[rounds];
  event checkFinish;
  //time startTime[rounds];
  time startTime;
  //time endTime[rounds];
  time endTime;

  event simulationStart;
  event testStart;
  integer totalNumOfCases=0;
  integer totalNumOfPasses=0;
  real epsilon_mult=3.0;

  string class_name = "464";
  string input_dir = "../inputs/input1";
  string output_dir = "../inputs/output1";
  integer rounds=1;
  integer timeout=100000000;
  integer num_of_testcases = 0;

  bit  [`Q_STATE_OUTPUT_SRAM_DATA_UPPER_BOUND-1:0 ]     mem     [int] ;

  integer num_results=72;
  int correctResult[MAX_ROUNDS];
  reg [15:0] result_array[int];
  reg [15:0] golden_result_array[int];
  int i;
  int j;
  int k;
  int q;
  int p;
  //---------------------------------------------------------------------------
  // General
  //
  reg                                   clk            ;
  reg                                   reset_n        ;
  reg                                   dut_valid        ;
  wire                                  dut_ready       ;

  //--------------------------------------------------------------------------
  //---------------------- q_state_output sram ---------------------------------------------
  wire                                                q_state_output_sram_write_enable  ;
  wire [`Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_output_sram_write_address ;
  wire [`Q_STATE_OUTPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_output_sram_write_data    ;
  wire [`Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_output_sram_read_address  ;
  wire [`Q_STATE_OUTPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_output_sram_read_data     ;
  //---------------------- q_state_input sram --------------------------------------------
  wire                                                q_state_input_sram_write_enable   ;
  wire [`Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND-1:0]  q_state_input_sram_write_address  ;
  wire [`Q_STATE_INPUT_SRAM_DATA_UPPER_BOUND-1:0]     q_state_input_sram_write_data     ;
  wire [`Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND-1:0]  q_state_input_sram_read_address   ;
  wire [`Q_STATE_INPUT_SRAM_DATA_UPPER_BOUND-1:0]     q_state_input_sram_read_data      ;
  //------------------ scratchpad sram --------------------------------------------
  wire                                                scratchpad_sram_write_enable      ;
  wire [`SCRATCHPAD_SRAM_ADDRESS_UPPER_BOUND-1:0]     scratchpad_sram_write_address     ;
  wire [`SCRATCHPAD_SRAM_DATA_UPPER_BOUND-1:0]        scratchpad_sram_write_data        ;
  wire [`SCRATCHPAD_SRAM_ADDRESS_UPPER_BOUND-1:0]     scratchpad_sram_read_address      ;
  wire [`SCRATCHPAD_SRAM_DATA_UPPER_BOUND-1:0]        scratchpad_sram_read_data         ;
  //----------------------- q_gates ------------------------------------------
  wire                                                q_gates_sram_write_enable         ;
  wire [`Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0]        q_gates_sram_write_address        ;
  wire [`Q_GATES_SRAM_DATA_UPPER_BOUND-1:0]           q_gates_sram_write_data           ;
  wire [`Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0]        q_gates_sram_read_address         ;
  wire [`Q_GATES_SRAM_DATA_UPPER_BOUND-1:0]           q_gates_sram_read_data            ;

  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  //SRAM
  //sram for q_state_inputs
  sram  #(.ADDR_WIDTH   (`Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND  ),
          .DATA_WIDTH   (`Q_STATE_INPUT_SRAM_DATA_UPPER_BOUND     ))
          q_state_input_mem  (
          .write_enable ( q_state_input_sram_write_enable         ),
          .write_address( q_state_input_sram_write_address        ),
          .write_data   ( q_state_input_sram_write_data           ),
          .read_address ( q_state_input_sram_read_address         ),
          .read_data    ( q_state_input_sram_read_data            ),
          .clk          ( clk                                     )
         );

  //sram for q_gates
  sram  #(.ADDR_WIDTH   (`Q_GATES_SRAM_ADDRESS_UPPER_BOUND        ),
          .DATA_WIDTH   (`Q_GATES_SRAM_DATA_UPPER_BOUND)          )
          q_gates_mem  (
          .write_enable ( q_gates_sram_write_enable               ),
          .write_address( q_gates_sram_write_address              ),
          .write_data   ( q_gates_sram_write_data                 ),
          .read_address ( q_gates_sram_read_address               ),
          .read_data    ( q_gates_sram_read_data                  ),
          .clk          ( clk                                     )
         );

  //sram for scratchpad
  sram  #(.ADDR_WIDTH   (`SCRATCHPAD_SRAM_ADDRESS_UPPER_BOUND     ),
          .DATA_WIDTH   (`SCRATCHPAD_SRAM_DATA_UPPER_BOUND)       )
          scratchpad_mem  (
          .write_enable ( scratchpad_sram_write_enable            ),
          .write_address( scratchpad_sram_write_address           ),
          .write_data   ( scratchpad_sram_write_data              ),
          .read_address ( scratchpad_sram_read_address            ),
          .read_data    ( scratchpad_sram_read_data               ),
          .clk          ( clk                                     )
         );

  //sram for q_state_outputs
  sram  #(.ADDR_WIDTH   (`Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND ),
          .DATA_WIDTH   (`Q_STATE_OUTPUT_SRAM_DATA_UPPER_BOUND)   )
          q_state_output_mem  (
          .write_enable ( q_state_output_sram_write_enable        ),
          .write_address( q_state_output_sram_write_address       ),
          .write_data   ( q_state_output_sram_write_data          ),
          .read_address ( q_state_output_sram_read_address        ),
          .read_data    ( q_state_output_sram_read_data           ),
          .clk          ( clk                                     )
         );


//---------------------------------------------------------------------------
// DUT
//---------------------------------------------------------------------------
  MyDesign dut(
//---------------------------------------------------------------------------
//System signals
          .reset_n                    (reset_n                      ),
          .clk                        (clk                          ),

//---------------------------------------------------------------------------
//Control signals
          .dut_valid                  (dut_valid                    ),
          .dut_ready                  (dut_ready                    ),

//---------------------------------------------------------------------------
//q_state_input SRAM interface
          .q_state_input_sram_write_enable        (q_state_input_sram_write_enable    ),
          .q_state_input_sram_write_address       (q_state_input_sram_write_address   ),
          .q_state_input_sram_write_data          (q_state_input_sram_write_data      ),
          .q_state_input_sram_read_address        (q_state_input_sram_read_address    ),
          .q_state_input_sram_read_data           (q_state_input_sram_read_data       ),

//---------------------------------------------------------------------------
//q_state_output SRAM interface
          .q_state_output_sram_write_enable       (q_state_output_sram_write_enable     ),
          .q_state_output_sram_write_address      (q_state_output_sram_write_address    ),
          .q_state_output_sram_write_data         (q_state_output_sram_write_data       ),
          .q_state_output_sram_read_address       (q_state_output_sram_read_address     ),
          .q_state_output_sram_read_data          (q_state_output_sram_read_data        ),

//---------------------------------------------------------------------------
//scratchpad SRAM interface
          .scratchpad_sram_write_enable   (scratchpad_sram_write_enable   ),
          .scratchpad_sram_write_address  (scratchpad_sram_write_address  ),
          .scratchpad_sram_write_data     (scratchpad_sram_write_data     ),
          .scratchpad_sram_read_address   (scratchpad_sram_read_address   ),
          .scratchpad_sram_read_data      (scratchpad_sram_read_data      ),

//---------------------------------------------------------------------------
//q_gates SRAM interface
          .q_gates_sram_write_enable      (q_gates_sram_write_enable    ),
          .q_gates_sram_write_address     (q_gates_sram_write_address   ),
          .q_gates_sram_write_data        (q_gates_sram_write_data      ),
          .q_gates_sram_read_address      (q_gates_sram_read_address    ),
          .q_gates_sram_read_data         (q_gates_sram_read_data       )
         );


  //---------------------------------------------------------------------------
  //  clk
  initial
    begin
        clk                     = 1'b0;
        forever # CLK_PHASE clk = ~clk;
    end


  initial
  begin

  end

  //---------------------------------------------------------------------------
  // get runtime args
  initial
  begin
    #1;
    if(!$value$plusargs("CLASS=%s",class_name)) class_name = "464";
    if($value$plusargs("ROUNDS=%d",rounds));
    if($value$plusargs("TIMEOUT=%d",timeout));
    if($value$plusargs("input_dir=%s",input_dir));
    if($value$plusargs("output_dir=%s",output_dir));
    if($value$plusargs("num_of_testcases=%d",num_of_testcases));
    $display("INFO: number of testcases: %d",num_of_testcases);
    if($value$plusargs("epsilon_mult=%f",epsilon_mult));

    $display("+CLASS+%s",class_name);
    repeat (5) @(posedge clk);
    ->simulationStart;
    @testStart
    wait_n_clks(timeout);
    $display("###################################");
    $display("             TIMEOUT               ");
    $display("###################################");
    $finish();
  end
  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  // Stimulus

  task wait_n_clks;
    input integer i;
  begin
    repeat(i)
    begin
      wait(clk);
      wait(!clk);
    end
  end
  endtask

  task handshack;
  begin
    wait(!clk);
    dut_valid = 1;
    wait(clk);
    wait(!dut_ready);
    wait(!clk);
    dut_valid = 0;
    wait(clk);
    wait(dut_ready);
    wait(!clk);
    wait(clk);
  end
  endtask

  function void check_output(integer testNum);
    integer passes;
    integer idx;
    real e;
    real check_real;
    real check_img ;
    real ref_real ;
    real ref_img ;
    real diff_real;
    real diff_img ;
    mem.delete();
    passes = 0;
    idx=0;
    e = $bitstoreal(64'h3CB0000000000000);
    $readmemh($sformatf("%s/test%0d_C.dat",output_dir,testNum),mem);
    $display($sformatf("INFO: reading %s/test%0d_C.dat",output_dir,testNum));
    foreach(mem[key])
    begin
      if(q_state_output_mem.mem.exists(key))
      begin
        check_real = $bitstoreal({1'b0,mem[key][126:64]});
        check_img = $bitstoreal({1'b0,mem[key][62:0]});
        ref_real = $bitstoreal({1'b0,q_state_output_mem.mem[key][126:64]});
        ref_img = $bitstoreal({1'b0,q_state_output_mem.mem[key][62:0]});
        if(ref_real >= check_real)
          diff_real = ref_real - check_real;
        else if(ref_real < check_real)
          diff_real = check_real - ref_real;
        if(ref_img >= check_img)
          diff_img = ref_img - check_img;
        else if(ref_img < check_img)
          diff_img = check_img - ref_img;
        if((diff_img <= (e*epsilon_mult)) && (diff_real <= (e*epsilon_mult)))
          passes+=1;
        else
        begin
          $display("INFO: Mismatch on %d",key);
          $display("INFO: ref     check   diff");
          $display("INFO: %7.30f, %7.30f, %7.30f", ref_real,check_real, diff_real);
          $display("INFO: %7.30f, %7.30f, %7.30f", ref_img,check_img, diff_img);
        end
      end
      else
        $display("ERROR: no entry at MEM[%d]", key);
    end
    $display("INFO: Number of cases        : %0d",mem.size());
    $display("INFO: Number of passed cases : %0d",passes);
    $display("INFO: presentage passed     : %7.2f",(passes * 100)/mem.size());
    $display("INFO: Test: %0d, Result: %7.2f\n",testNum ,(passes * 100)/mem.size());
    totalNumOfCases=totalNumOfCases + mem.size();
    totalNumOfPasses=totalNumOfPasses + passes;
  endfunction

  task test;
    input integer testNum;
  begin

    $display("INFO: ######## Running Test: %0d ########",testNum);
    wait_n_clks(10);
    q_state_input_mem.loadMem($sformatf("%s/test%0d_B.dat",input_dir,testNum));
    q_gates_mem.loadMem($sformatf("%s/test%0d_A.dat",input_dir,testNum));
    wait_n_clks(10);
    handshack();
    wait_n_clks(10);
    check_output(testNum);
    wait_n_clks(10);
  end
  endtask



  initial
  begin
    wait(simulationStart);
    reset_n = 1;
    wait_n_clks(10);
    reset_n = 0;
    wait_n_clks(20);
    dut_valid = 0;
    wait_n_clks(20);
    reset_n = 1;
    wait_n_clks(20);
    $display("INFO: DONE WITH RESETING DUT");
    ->testStart;
    startTime=$time();
    for(int i=1;i<num_of_testcases+1;i++)
    begin
      test(i);
    end
    endTime=$time();
    if(totalNumOfCases != 0)
    begin
      $display("INFO: Total number of cases  : %0d",totalNumOfCases);
      $display("INFO: Total number of passes : %0d",totalNumOfPasses);
      $display("INFO: Finial Results         : %6.2f",(totalNumOfPasses * 100)/totalNumOfCases);
      $display("INFO: Finial Time Result     : %0t ns",endTime-startTime);
      $display("INFO: Finial Cycle Result    : %0d cycles\n",((endTime-startTime)/CLK_PHASE));
    end
    $finish();
  end
endmodule
