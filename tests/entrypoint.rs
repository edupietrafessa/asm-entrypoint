#[cfg(test)]
mod tests {
    use mollusk_svm::{result::Check, Mollusk};
    use solana_sdk::account::Account;
    use solana_sdk::instruction::{AccountMeta, Instruction};
    use solana_sdk::native_token::LAMPORTS_PER_SOL;
    use solana_sdk::pubkey::Pubkey;
    use solana_sdk::signature::Keypair;
    use solana_sdk::signer::Signer;

    fn setup_test_context() -> (Mollusk, Pubkey, Vec<(Pubkey, Account)>) {
        let program_id = Keypair::new().pubkey();

        let mollusk = Mollusk::new(&program_id, "deploy/entrypoint");

        let acct_one_pk = Keypair::new().pubkey();
        let acct_one = Account {
            data: b"Account 1!".to_vec(),
            lamports: LAMPORTS_PER_SOL,
            owner: program_id,
            rent_epoch: u64::MAX,
            ..Default::default()
        };

        let acct_two_pk = Keypair::new().pubkey();
        let acct_two = Account::new(LAMPORTS_PER_SOL / 20, 0, &program_id);

        (
            mollusk,
            program_id,
            vec![(acct_one_pk, acct_one), (acct_two_pk, acct_two)],
        )
    }

    #[test]
    fn test_instruction_data() {
        let (mollusk, program_id, accounts) = setup_test_context();

        let instruction = Instruction::new_with_bytes(
            program_id,
            &[&[0], b"instruction data!!!".as_slice()].concat(),
            vec![
                AccountMeta::new_readonly(accounts[0].0, true),
                AccountMeta::new_readonly(accounts[1].0, true),
                AccountMeta::new_readonly(accounts[0].0, false),
            ],
        );

        let result =
            mollusk.process_and_validate_instruction(&instruction, &accounts, &[Check::success()]);
        assert!(!result.program_result.is_err());
    }

    #[test]
    fn test_program_id() {
        let (mollusk, program_id, accounts) = setup_test_context();

        let instruction = Instruction::new_with_bytes(
            program_id,
            &[&[1], program_id.to_bytes().as_slice()].concat(),
            vec![
                AccountMeta::new_readonly(accounts[0].0, true),
                AccountMeta::new_readonly(accounts[1].0, true),
                AccountMeta::new_readonly(accounts[0].0, false),
            ],
        );

        let result =
            mollusk.process_and_validate_instruction(&instruction, &accounts, &[Check::success()]);
        assert!(!result.program_result.is_err());
    }

    #[test]
    fn test_accounts() {
        let (mollusk, program_id, accounts) = setup_test_context();

        let account_index = 2;
        let instruction = Instruction::new_with_bytes(
            program_id,
            &[2, account_index],
            vec![
                AccountMeta::new_readonly(accounts[0].0, true),
                AccountMeta::new_readonly(accounts[1].0, true),
                AccountMeta::new_readonly(accounts[0].0, false),
            ],
        );

        let result =
            mollusk.process_and_validate_instruction(&instruction, &accounts, &[Check::success()]);
        assert!(!result.program_result.is_err());
    }
}
