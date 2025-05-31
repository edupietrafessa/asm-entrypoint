.equ ACCOUNT_SIZE, 88
.equ MAX_PERMITTED_ACCOUNT_DATA_SIZE, 10240

.equ PROGRAM_ID_PTR, 0x200000000
.equ ACCOUNT_PTR_SLICE, 0x200000008
.equ INST_DATA_PTR, 0x200000148

.equ STACK_START, 0x200000150


.globl entrypoint

entrypoint:
  ldxdw r5, [r1+0] # we get number of accounts -> r5, no of accounts
  add64 r1, 8 # we move our input data forward by 8 bytes
  lddw r7, ACCOUNT_PTR_SLICE # we want to set our account[] pointer, from the initial stack address
  
get_accounts:
  jeq r5, 0, get_instruction_data # check if the number of accounts we need to check is 0
  ldxb r6, [r1 + 0] # get the first byte of the r1 (each account from imput)
  jeq r6, 255, get_non_duplicate_account # jump to get_non_duplicate if it is not a duplicate
  jne r6, 255, get_duplicate_account # jump to get_duplicate if it is a duplicate

get_non_duplicate_account:
  stxdw [r7 + 0], r1 # store the address of the account at the input data, on the stack
  ldxdw r8, [r1 + 8 + 32 + 32 + 8] # get the account data length
  add64 r1, ACCOUNT_SIZE + MAX_PERMITTED_ACCOUNT_DATA_SIZE + 8 # move to the end of the account
  add64 r1, r8 # offset account data copy
  mod64 r8, 8 # check if the account data is aligned
  jeq r8, 0, skip_account_data_padding # skip adding paddng if account data is aligned
  mov64 r6, r8 # store bytes offset in r6 
  lddw r8, 8 # set the alignment in r8
  sub64 r8, r6 # get remaining padding bytes
skip_account_data_padding:
  add64 r1, r8 # add padding offset
  add64 r7, 8 # move account slice counter to the next index
  sub64 r5, 1 # decrement the account loop counter
  ja get_accounts # loop again

get_duplicate_account:
  mul64 r6, 8 # calculate the offset to get the duplicate 
  lddw r8, ACCOUNT_PTR_SLICE # load the account ptr slice address on r1
  add64 r6, r8 # get the address where the duplicate account ptr is stored using the offset
  ldxdw r6, [r6 + 0] # get the address of the duplicate account
  stxdw [r7 + 0], r6 # store the address in the account_ptr_slice
  add64 r1, 8 # move to the next account
  add64 r7, 8 # move account slice counter to the next index
  sub64 r5, 1 # decrement the account loop counter
  ja get_accounts # loop again

get_instruction_data:
  ldxdw r2, [r1 + 0] # get the length of the instruction data
  add64 r1, 8 # get the instrucion data location
  lddw r7, INST_DATA_PTR # load the inst data ptr address on r7
  stxdw [r7 + 0], r1 # store the instruction data location on the pointer
  add64 r1, r2 # add the instruction data offset

get_program_id:
  lddw r7, PROGRAM_ID_PTR # load the program id ptr
  stxdw [r7 + 0], r1 # store the program id location at the ptr

# instructions

get_instruction:
  lddw r1, INST_DATA_PTR # load the ix data ptr on the register
  ldxdw r1, [r1 + 0] # get the instruction data location from ptr
  ldxb r2, [r1 + 0] # read the first byte
  jeq r2, 0, check_instruction_data_instruction
  jeq r2, 1, check_program_id_instruction
  jeq r2, 2, check_account_instruction
  ja error_invalid_discriminator

check_instruction_data_instruction:
  ldxdw r2, [r1 - 8] # get the instruction data length
  sub64 r2, 1 # subtract one, the instruction discriminator
  add64 r1, 1 # move the data ptr up one byte, offset the discriminaotr
  call sol_log_ # log the instruction data
  exit

check_program_id_instruction:
  add64 r1, 1 # move up one byte since we already inst data loaded on r1
  mov64 r2, r1 # move the instruction data to r2
  lddw r1, PROGRAM_ID_PTR # load the program id ptr to r1
  ldxdw r1, [r1 + 0] # load the program id location to r1
  call sol_log_pubkey # log out the program id
  // mov64 r3, 32 # pubkey length
  // call sol_memcmp_ # compare pubkey bytes
  // jeq r0, 0, error_pubkey_not_equal # error if pubkey bytes are not equal
  exit

check_account_instruction:
  lddw r2, 0x400000000 # get accounts length location
  ldxdw r2, [r2 + 0] # get accounts length
  jeq r2, 0, error_no_account_provided # throw error if there are no accounts
  ldxb r2, [r1 + 1] # get index of account
  mul64 r2, 8 # get the offset in the account ptr slice
  lddw r1, ACCOUNT_PTR_SLICE # get the offset in the account ptr slice
  add64 r1, r2 # get the pointer to the account
  ldxdw r1, [r1 + 0] # get the account address location
  add64 r1, 8 # get account pubkey
  call sol_log_pubkey # log the account pubkey
  add64 r1, 32 # get account owner pubkey
  call sol_log_pubkey # log the account owner pubkey
  ldxdw r2, [r1 + 32 + 8] # get account data length
  jeq r2, 0, without_data # process account without data
with_data:
  add64 r1, 32 + 8 + 8 # move pointer to account data
  ja log # jump to log
without_data:
  lddw r1, no_acct_data_message # get the static str to print
  mov64 r2, 18 # length of static str
log:
  call sol_log_
  exit

error_invalid_discriminator:
  mov64 r0, 0x1
	exit

error_pubkey_not_equal:
  mov64 r0, 0x2
	exit

error_no_account_provided:
  mov64 r0, 0x3
	exit

.section .rodata
  no_acct_data_message: .ascii "No Account Data!!!"
