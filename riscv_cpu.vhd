-- =============================================================================
-- RISC-V CPU Top-Level - Pipeline de 5 estágios (RV32I)
-- Integra todos os componentes da CPU
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity riscv_cpu is
    port (
        clk_i           : in  std_logic;
        reset_i         : in  std_logic;
        load_enable_i   : in  std_logic;  -- Durante carga de memória, CPU pausa
        
        -- Interface com Memória de Instruções (ROM)
        imem_addr_o     : out std_logic_vector(31 downto 0);
        imem_data_i     : in  std_logic_vector(31 downto 0);
        
        -- Interface com Memória de Dados (RAM)
        dmem_addr_o     : out std_logic_vector(31 downto 0);
        dmem_wdata_o    : out std_logic_vector(31 downto 0);  -- Dados para escrita
        dmem_rdata_i    : in  std_logic_vector(31 downto 0);  -- Dados lidos
        dmem_we_o       : out std_logic;                       -- Write enable
        
        -- Debug outputs (para aferir estados internos)
        pc_debug_o      : out std_logic_vector(31 downto 0);
        instr_debug_o   : out std_logic_vector(31 downto 0);
        alu_result_debug_o : out std_logic_vector(31 downto 0);
        reg_debug_o     : out std_logic_vector(31 downto 0);
        reg_sel_i       : in  std_logic_vector(4 downto 0);
        -- Debug dos estágios do pipeline
        stage_if_pc_o   : out std_logic_vector(31 downto 0);
        stage_id_pc_o   : out std_logic_vector(31 downto 0);
        stage_ex_pc_o   : out std_logic_vector(31 downto 0);
        -- Debug de hazards
        hazard_stall_o  : out std_logic;
        hazard_flush_o  : out std_logic
    );
end entity riscv_cpu;

architecture rtl of riscv_cpu is

    -- =========================================================================
    -- Sinais do Estágio IF (Instruction Fetch)
    -- =========================================================================
    signal if_pc          : std_logic_vector(31 downto 0);
    signal if_pc_plus4    : std_logic_vector(31 downto 0);
    signal if_instruction : std_logic_vector(31 downto 0);
    
    -- =========================================================================
    -- Sinais do Registrador IF/ID
    -- =========================================================================
    signal id_pc          : std_logic_vector(31 downto 0);
    signal id_pc_plus4    : std_logic_vector(31 downto 0);
    signal id_instruction : std_logic_vector(31 downto 0);
    
    -- =========================================================================
    -- Sinais do Estágio ID (Instruction Decode)
    -- =========================================================================
    -- Campos decodificados
    signal id_opcode      : std_logic_vector(6 downto 0);
    signal id_rd          : std_logic_vector(4 downto 0);
    signal id_funct3      : std_logic_vector(2 downto 0);
    signal id_rs1         : std_logic_vector(4 downto 0);
    signal id_rs2         : std_logic_vector(4 downto 0);
    signal id_funct7      : std_logic_vector(6 downto 0);
    signal id_imm         : std_logic_vector(31 downto 0);
    signal id_instr_type  : std_logic_vector(2 downto 0);
    -- Dados lidos do banco de registradores
    signal id_rs1_data    : std_logic_vector(31 downto 0);
    signal id_rs2_data    : std_logic_vector(31 downto 0);
    -- Sinais de controle
    signal id_reg_write   : std_logic;
    signal id_mem_to_reg  : std_logic;
    signal id_mem_write   : std_logic;
    signal id_mem_read    : std_logic;
    signal id_alu_src     : std_logic;
    signal id_alu_ctrl    : std_logic_vector(3 downto 0);
    signal id_branch      : std_logic;
    signal id_jump        : std_logic;
    signal id_auipc       : std_logic;
    signal id_jalr        : std_logic;
    signal id_lui         : std_logic;
    
    -- =========================================================================
    -- Sinais do Registrador ID/EX
    -- =========================================================================
    signal ex_pc          : std_logic_vector(31 downto 0);
    signal ex_pc_plus4    : std_logic_vector(31 downto 0);
    signal ex_rs1_data    : std_logic_vector(31 downto 0);
    signal ex_rs2_data    : std_logic_vector(31 downto 0);
    signal ex_imm         : std_logic_vector(31 downto 0);
    signal ex_rs1_addr    : std_logic_vector(4 downto 0);
    signal ex_rs2_addr    : std_logic_vector(4 downto 0);
    signal ex_rd_addr     : std_logic_vector(4 downto 0);
    signal ex_funct3      : std_logic_vector(2 downto 0);
    signal ex_reg_write   : std_logic;
    signal ex_mem_to_reg  : std_logic;
    signal ex_mem_write   : std_logic;
    signal ex_mem_read    : std_logic;
    signal ex_alu_src     : std_logic;
    signal ex_alu_ctrl    : std_logic_vector(3 downto 0);
    signal ex_branch      : std_logic;
    signal ex_jump        : std_logic;
    signal ex_auipc       : std_logic;
    signal ex_jalr        : std_logic;
    signal ex_lui         : std_logic;
    
    -- =========================================================================
    -- Sinais do Estágio EX (Execute)
    -- =========================================================================
    signal ex_alu_a       : std_logic_vector(31 downto 0);
    signal ex_alu_b       : std_logic_vector(31 downto 0);
    signal ex_alu_result  : std_logic_vector(31 downto 0);
    signal ex_alu_zero    : std_logic;
    signal ex_branch_taken: std_logic;
    signal ex_target_addr : std_logic_vector(31 downto 0);
    signal ex_forward_a   : std_logic_vector(1 downto 0);
    signal ex_forward_b   : std_logic_vector(1 downto 0);
    signal ex_rs1_forwarded : std_logic_vector(31 downto 0);
    signal ex_rs2_forwarded : std_logic_vector(31 downto 0);
    
    -- =========================================================================
    -- Sinais do Registrador EX/MEM
    -- =========================================================================
    signal mem_pc_plus4   : std_logic_vector(31 downto 0);
    signal mem_alu_result : std_logic_vector(31 downto 0);
    signal mem_rs2_data   : std_logic_vector(31 downto 0);
    signal mem_rd_addr    : std_logic_vector(4 downto 0);
    signal mem_zero       : std_logic;
    signal mem_reg_write  : std_logic;
    signal mem_mem_to_reg : std_logic;
    signal mem_mem_write  : std_logic;
    signal mem_mem_read   : std_logic;
    signal mem_branch     : std_logic;
    signal mem_jump       : std_logic;
    
    -- =========================================================================
    -- Sinais do Estágio MEM (Memory Access)
    -- =========================================================================
    signal mem_read_data  : std_logic_vector(31 downto 0);
    
    -- =========================================================================
    -- Sinais do Registrador MEM/WB
    -- =========================================================================
    signal wb_pc_plus4    : std_logic_vector(31 downto 0);
    signal wb_alu_result  : std_logic_vector(31 downto 0);
    signal wb_mem_data    : std_logic_vector(31 downto 0);
    signal wb_rd_addr     : std_logic_vector(4 downto 0);
    signal wb_reg_write   : std_logic;
    signal wb_mem_to_reg  : std_logic;
    signal wb_jump        : std_logic;
    
    -- =========================================================================
    -- Sinais do Estágio WB (Write Back)
    -- =========================================================================
    signal wb_write_data  : std_logic_vector(31 downto 0);
    
    -- =========================================================================
    -- Sinais de Controle de Hazards
    -- =========================================================================
    signal stall_if       : std_logic;
    signal stall_id       : std_logic;
    signal flush_id       : std_logic;
    signal flush_ex       : std_logic;
    signal hazard_type    : std_logic_vector(1 downto 0);

begin

    -- =========================================================================
    -- Estágio IF: Instruction Fetch
    -- =========================================================================
    
    -- Program Counter
    U_PC : entity work.program_counter
        port map (
            clk_i          => clk_i,
            reset_i        => reset_i,
            stall_i        => stall_if,
            load_enable_i  => load_enable_i,
            branch_taken_i => ex_branch_taken,
            jump_i         => ex_jump,
            target_addr_i  => ex_target_addr,
            pc_o           => if_pc,
            pc_plus4_o     => if_pc_plus4
        );
    
    -- Endereço para memória de instruções
    imem_addr_o    <= if_pc;
    if_instruction <= imem_data_i;
    
    -- =========================================================================
    -- Registrador IF/ID
    -- =========================================================================
    
    U_IF_ID : entity work.if_id_reg
        port map (
            clk_i         => clk_i,
            reset_i       => reset_i,
            stall_i       => stall_id,
            flush_i       => flush_id,
            load_enable_i => load_enable_i,
            pc_i          => if_pc,
            pc_plus4_i    => if_pc_plus4,
            instruction_i => if_instruction,
            pc_o          => id_pc,
            pc_plus4_o    => id_pc_plus4,
            instruction_o => id_instruction
        );
    
    -- =========================================================================
    -- Estágio ID: Instruction Decode
    -- =========================================================================
    
    -- Decodificador de instruções
    U_DECODER : entity work.instruction_decoder
        port map (
            instruction_i => id_instruction,
            opcode_o      => id_opcode,
            rd_o          => id_rd,
            funct3_o      => id_funct3,
            rs1_o         => id_rs1,
            rs2_o         => id_rs2,
            funct7_o      => id_funct7,
            imm_o         => id_imm,
            instr_type_o  => id_instr_type
        );
    
    -- Unidade de controle
    U_CONTROL : entity work.control_unit
        port map (
            opcode_i     => id_opcode,
            funct3_i     => id_funct3,
            funct7_i     => id_funct7,
            reg_write_o  => id_reg_write,
            mem_to_reg_o => id_mem_to_reg,
            mem_write_o  => id_mem_write,
            mem_read_o   => id_mem_read,
            alu_src_o    => id_alu_src,
            alu_ctrl_o   => id_alu_ctrl,
            branch_o     => id_branch,
            jump_o       => id_jump,
            auipc_o      => id_auipc,
            jalr_o       => id_jalr,
            lui_o        => id_lui
        );
    
    -- Banco de registradores
    U_REGFILE : entity work.register_file
        port map (
            clk_i       => clk_i,
            reset_i     => reset_i,
            we_i        => wb_reg_write,
            rs1_addr_i  => id_rs1,
            rs2_addr_i  => id_rs2,
            rd_addr_i   => wb_rd_addr,
            rd_data_i   => wb_write_data,
            rs1_data_o  => id_rs1_data,
            rs2_data_o  => id_rs2_data,
            reg_debug_o => reg_debug_o,
            reg_sel_i   => reg_sel_i
        );
    
    -- =========================================================================
    -- Registrador ID/EX
    -- =========================================================================
    
    U_ID_EX : entity work.id_ex_reg
        port map (
            clk_i         => clk_i,
            reset_i       => reset_i,
            stall_i       => '0',
            flush_i       => flush_ex,
            load_enable_i => load_enable_i,
            pc_i          => id_pc,
            pc_plus4_i    => id_pc_plus4,
            rs1_data_i    => id_rs1_data,
            rs2_data_i    => id_rs2_data,
            imm_i         => id_imm,
            rs1_addr_i    => id_rs1,
            rs2_addr_i    => id_rs2,
            rd_addr_i     => id_rd,
            funct3_i      => id_funct3,
            reg_write_i   => id_reg_write,
            mem_to_reg_i  => id_mem_to_reg,
            mem_write_i   => id_mem_write,
            mem_read_i    => id_mem_read,
            alu_src_i     => id_alu_src,
            alu_ctrl_i    => id_alu_ctrl,
            branch_i      => id_branch,
            jump_i        => id_jump,
            auipc_i       => id_auipc,
            jalr_i        => id_jalr,
            lui_i         => id_lui,
            pc_o          => ex_pc,
            pc_plus4_o    => ex_pc_plus4,
            rs1_data_o    => ex_rs1_data,
            rs2_data_o    => ex_rs2_data,
            imm_o         => ex_imm,
            rs1_addr_o    => ex_rs1_addr,
            rs2_addr_o    => ex_rs2_addr,
            rd_addr_o     => ex_rd_addr,
            funct3_o      => ex_funct3,
            reg_write_o   => ex_reg_write,
            mem_to_reg_o  => ex_mem_to_reg,
            mem_write_o   => ex_mem_write,
            mem_read_o    => ex_mem_read,
            alu_src_o     => ex_alu_src,
            alu_ctrl_o    => ex_alu_ctrl,
            branch_o      => ex_branch,
            jump_o        => ex_jump,
            auipc_o       => ex_auipc,
            jalr_o        => ex_jalr,
            lui_o         => ex_lui
        );
    
    -- =========================================================================
    -- Estágio EX: Execute
    -- =========================================================================
    
    -- Unidade de Forwarding
    U_FORWARDING : entity work.forwarding_unit
        port map (
            rs1_ex_i        => ex_rs1_addr,
            rs2_ex_i        => ex_rs2_addr,
            rd_mem_i        => mem_rd_addr,
            reg_write_mem_i => mem_reg_write,
            rd_wb_i         => wb_rd_addr,
            reg_write_wb_i  => wb_reg_write,
            forward_a_o     => ex_forward_a,
            forward_b_o     => ex_forward_b
        );
    
    -- Mux de forwarding para operando A (rs1)
    P_FORWARD_A_MUX : process(ex_forward_a, ex_rs1_data, mem_alu_result, wb_write_data)
    begin
        case ex_forward_a is
            when "01"   => ex_rs1_forwarded <= mem_alu_result;
            when "10"   => ex_rs1_forwarded <= wb_write_data;
            when others => ex_rs1_forwarded <= ex_rs1_data;
        end case;
    end process P_FORWARD_A_MUX;
    
    -- Mux de forwarding para operando B (rs2)
    P_FORWARD_B_MUX : process(ex_forward_b, ex_rs2_data, mem_alu_result, wb_write_data)
    begin
        case ex_forward_b is
            when "01"   => ex_rs2_forwarded <= mem_alu_result;
            when "10"   => ex_rs2_forwarded <= wb_write_data;
            when others => ex_rs2_forwarded <= ex_rs2_data;
        end case;
    end process P_FORWARD_B_MUX;
    
    -- Seleção do operando A da ALU
    -- Para AUIPC, usa PC; para LUI, usa 0; caso contrário, usa rs1
    P_ALU_A_SELECT : process(ex_auipc, ex_lui, ex_pc, ex_rs1_forwarded)
    begin
        if ex_auipc = '1' then
            ex_alu_a <= ex_pc;
        elsif ex_lui = '1' then
            ex_alu_a <= (others => '0');
        else
            ex_alu_a <= ex_rs1_forwarded;
        end if;
    end process P_ALU_A_SELECT;
    
    -- Seleção do operando B da ALU
    -- Se alu_src='1', usa imediato; caso contrário, usa rs2
    ex_alu_b <= ex_imm when ex_alu_src = '1' else ex_rs2_forwarded;
    
    -- ALU
    U_ALU : entity work.alu
        port map (
            a_i        => ex_alu_a,
            b_i        => ex_alu_b,
            alu_ctrl_i => ex_alu_ctrl,
            result_o   => ex_alu_result,
            zero_o     => ex_alu_zero,
            carry_o    => open,
            overflow_o => open
        );
    
    -- Comparador de Branch
    U_BRANCH_CMP : entity work.branch_comparator
        port map (
            a_i            => ex_rs1_forwarded,
            b_i            => ex_rs2_forwarded,
            funct3_i       => ex_funct3,
            branch_i       => ex_branch,
            branch_taken_o => ex_branch_taken,
            eq_o           => open,
            ne_o           => open
        );
    
    -- Cálculo do endereço de destino (branch/jump)
    P_TARGET_ADDR : process(ex_pc, ex_imm, ex_jalr, ex_rs1_forwarded)
    begin
        if ex_jalr = '1' then
            -- JALR: rs1 + imm (com bit 0 forçado a 0)
            ex_target_addr <= std_logic_vector(unsigned(ex_rs1_forwarded) + unsigned(ex_imm));
            ex_target_addr(0) <= '0';
        else
            -- JAL/Branch: PC + imm
            ex_target_addr <= std_logic_vector(unsigned(ex_pc) + unsigned(ex_imm));
        end if;
    end process P_TARGET_ADDR;
    
    -- =========================================================================
    -- Unidade de Detecção de Hazards
    -- =========================================================================
    
    U_HAZARD : entity work.hazard_unit
        port map (
            rs1_id_i       => id_rs1,
            rs2_id_i       => id_rs2,
            rd_ex_i        => ex_rd_addr,
            mem_read_ex_i  => ex_mem_read,
            branch_taken_i => ex_branch_taken,
            jump_i         => ex_jump,
            stall_if_o     => stall_if,
            stall_id_o     => stall_id,
            flush_id_o     => flush_id,
            flush_ex_o     => flush_ex,
            hazard_type_o  => hazard_type
        );
    
    -- =========================================================================
    -- Registrador EX/MEM
    -- =========================================================================
    
    U_EX_MEM : entity work.ex_mem_reg
        port map (
            clk_i         => clk_i,
            reset_i       => reset_i,
            flush_i       => '0',
            load_enable_i => load_enable_i,
            pc_plus4_i    => ex_pc_plus4,
            alu_result_i  => ex_alu_result,
            rs2_data_i    => ex_rs2_forwarded,
            rd_addr_i     => ex_rd_addr,
            zero_i        => ex_alu_zero,
            reg_write_i   => ex_reg_write,
            mem_to_reg_i  => ex_mem_to_reg,
            mem_write_i   => ex_mem_write,
            mem_read_i    => ex_mem_read,
            branch_i      => ex_branch,
            jump_i        => ex_jump,
            pc_plus4_o    => mem_pc_plus4,
            alu_result_o  => mem_alu_result,
            rs2_data_o    => mem_rs2_data,
            rd_addr_o     => mem_rd_addr,
            zero_o        => mem_zero,
            reg_write_o   => mem_reg_write,
            mem_to_reg_o  => mem_mem_to_reg,
            mem_write_o   => mem_mem_write,
            mem_read_o    => mem_mem_read,
            branch_o      => mem_branch,
            jump_o        => mem_jump
        );
    
    -- =========================================================================
    -- Estágio MEM: Memory Access
    -- =========================================================================
    
    -- Interface com memória de dados
    dmem_addr_o  <= mem_alu_result;
    dmem_wdata_o <= mem_rs2_data;
    dmem_we_o    <= mem_mem_write and (not load_enable_i);
    mem_read_data <= dmem_rdata_i;
    
    -- =========================================================================
    -- Registrador MEM/WB
    -- =========================================================================
    
    U_MEM_WB : entity work.mem_wb_reg
        port map (
            clk_i         => clk_i,
            reset_i       => reset_i,
            load_enable_i => load_enable_i,
            pc_plus4_i    => mem_pc_plus4,
            alu_result_i  => mem_alu_result,
            mem_data_i    => mem_read_data,
            rd_addr_i     => mem_rd_addr,
            reg_write_i   => mem_reg_write,
            mem_to_reg_i  => mem_mem_to_reg,
            jump_i        => mem_jump,
            pc_plus4_o    => wb_pc_plus4,
            alu_result_o  => wb_alu_result,
            mem_data_o    => wb_mem_data,
            rd_addr_o     => wb_rd_addr,
            reg_write_o   => wb_reg_write,
            mem_to_reg_o  => wb_mem_to_reg,
            jump_o        => wb_jump
        );
    
    -- =========================================================================
    -- Estágio WB: Write Back
    -- =========================================================================
    
    -- Seleção do dado a ser escrito no banco de registradores
    P_WB_DATA_SELECT : process(wb_jump, wb_mem_to_reg, wb_pc_plus4, wb_mem_data, wb_alu_result)
    begin
        if wb_jump = '1' then
            -- JAL/JALR: salva PC+4 (endereço de retorno)
            wb_write_data <= wb_pc_plus4;
        elsif wb_mem_to_reg = '1' then
            -- Load: usa dado da memória
            wb_write_data <= wb_mem_data;
        else
            -- Outras instruções: usa resultado da ALU
            wb_write_data <= wb_alu_result;
        end if;
    end process P_WB_DATA_SELECT;
    
    -- =========================================================================
    -- Saídas de Debug
    -- =========================================================================
    
    pc_debug_o         <= if_pc;
    instr_debug_o      <= id_instruction;
    alu_result_debug_o <= ex_alu_result;
    stage_if_pc_o      <= if_pc;
    stage_id_pc_o      <= id_pc;
    stage_ex_pc_o      <= ex_pc;
    hazard_stall_o     <= stall_if or stall_id;
    hazard_flush_o     <= flush_id or flush_ex;

end architecture rtl;
