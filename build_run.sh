cargo build --release
./target/release/opennorm transpile licences/mit.strict.md --strict > ./tmp/MIT/STRICT.lean
lean ./tmp/MIT/STRICT.lean
