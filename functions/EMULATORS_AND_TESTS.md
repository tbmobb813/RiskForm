# Emulators & Tests (local)

Quick steps to run the Cloud Functions emulator and the integration tests locally:

- Install dependencies (from the functions folder):

```bash
cd functions
npm install
```

- Start the emulators (functions + firestore) in one terminal:

```bash
cd functions
npm run serve
# or, if you prefer npx:
# npx firebase emulators:start --only functions,firestore
```

- In another terminal, point tests at the Firestore emulator and run integration tests:

```bash
cd functions
export FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
npm run test:integration
```

Notes:
- `npm run serve` builds the functions (`npm run build`) then starts the emulators. If the Firestore emulator downloads on first run it may take a moment.
- The integration tests use `firebase-functions-test` and expect the emulators to be running.
