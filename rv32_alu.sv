module rv32_alu (

    input clk,  //1
    input reset, //2
    input  logic [31:0] rs1_data_in,  // Source register 1 //3
    input  logic [31:0] rs2_data_in,  // Source register 2  //4
    input  logic [31:0] pc_in,        // Program Counter (for AUIPC, JAL) //5
    
    output logic [31:0] alu_out,   // ALU result  //6
    
    input logic [31:0] iw_in    //7
    
);

    logic [2:0]  funct3;    // Function bits
    logic [6:0]  opcode;    // Instruction opcode
    logic [4:0]  shamt;     // Shift amount (for shift instructions)
    logic [31:0] imm;       // Immediate value (for I-type instructions)
    logic [31:0] immEX;
    
    logic [11:0] immI; 
    
    logic [6:0]  funct7;    // Upper function bits (R-type only)
    logic [31:0] ra_out;    // Return address (for JAL, JALR) //rd-> out
    logic zero_flag;        // Zero flag (alu_out == 0)
    logic sign_flag;         // Sign flag (alu_out[31] == 1)
    
    always_comb begin
    funct3 <= iw_in[14:12];
    opcode <= iw_in[6:0];
    shamt  <= iw_in[24:20];
    funct7 <= iw_in[31:25];
    immI   <= iw_in[31:20];
    immEX  <= {{20{iw_in[31]}}, iw_in[31:20]}; 

     
     
        case (opcode)
            // Arithmetic operations Rrithmetic
            7'b0110011: begin // R-Type
                case ({funct7, funct3})
                    10'b0000000000: alu_out = rs1_data_in + rs2_data_in; // ADD
                    10'b0100000000: alu_out = rs1_data_in - rs2_data_in; // SUB
                    10'b0000000001: alu_out = rs1_data_in << rs2_data_in[4:0];//sll
                    10'b0000000010: alu_out = ($signed(rs1_data_in) < $signed(rs2_data_in)) ? 32'b1 : 32'b0; // SLT
                    10'b0000000011: alu_out = (rs1_data_in < rs2_data_in) ? 32'b1 : 32'b0; // SLTU
                    10'b0000000100: alu_out = rs1_data_in ^ rs2_data_in; // XOR
                    10'b0000000101: alu_out = rs1_data_in >> rs2_data_in[4:0]; // srl
                    10'b0100000101: alu_out = $signed(rs1_data_in) >>> rs2_data_in[4:0]; // sra
                    10'b0000000110: alu_out = rs1_data_in | rs2_data_in; // OR
                    10'b0000000111: alu_out = rs1_data_in & rs2_data_in; // AND
                    default: alu_out = 32'b0;
                endcase
            end
            // Immediate operations
            7'b0010011: begin // I-Type (ADDI, ANDI, ORI, XORI, SLTI, SLTIU)
                case (funct3)
                    3'b000: alu_out = rs1_data_in + immI; // ADDI
                    3'b111: alu_out = rs1_data_in & immI; // ANDI
                    3'b110: alu_out = rs1_data_in | immI; // ORI
                    3'b100: alu_out = rs1_data_in ^ immI; // XORI
                    3'b010: alu_out = ($signed(rs1_data_in) < $signed(immI)) ? 32'b1 : 32'b0; // SLTI
                    3'b011: alu_out = (rs1_data_in < immI) ? 32'b1 : 32'b0; // SLTIU
                    default: alu_out = 32'b0;
                endcase
            end
            // Shift instructions
            7'b0010011: begin //I-Type shift operations
                case ({funct7, funct3})
                    10'b0000000001: alu_out = rs1_data_in << shamt; // SLLI
                    10'b0000000101: alu_out = rs1_data_in >> shamt; // SRLI
                    10'b0100000101: alu_out = $signed(rs1_data_in) >>> shamt; // SRAI
                    default: alu_out = 32'b0;
                endcase
            end
            // Jump instructions
            7'b1101111: begin // JAL
                alu_out = pc_in + imm;
                ra_out = pc_in + 4;
            end
            
            7'b1100111: begin // JALR
                if (funct3 == 3'b000) begin
                    alu_out = (rs1_data_in + immEX) & ~32'b1; //sign-extended immI. ~32'b1 drops the lsat bit
                    ra_out = pc_in + 4;  // Return address
                end else begin
                    alu_out = 32'b0;
                    ra_out = 32'b0;
                end
            end
            default: alu_out = 32'b0; 

        endcase
    end

    // Flags
    assign zero_flag = (alu_out == 32'b0);
    assign sign_flag = alu_out[31];

endmodule
