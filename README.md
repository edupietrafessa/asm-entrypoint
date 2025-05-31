# ASM Entrypoint

Generic solana entrypoint deserialize written in ASM. Useful for multi-instruction solana programs written in ASM.


### Running the program.

First, setup Solana platform tools by running:

```sh
./setup-solana-llvm.sh
```

Next, build the program with:

```sh
make
```

Test the compiled program, using:

```sh
cargo test
```
