const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

async function runTests() {
  console.log('--- Starting Firebase Realtime Database Security Rules Tests ---');

  const rulesPath = path.resolve(__dirname, '../database.rules.json');
  const rules = fs.readFileSync(rulesPath, 'utf8');

  const testEnv = await initializeTestEnvironment({
    projectId: 'demo-kerkom-security-test',
    database: {
      host: '127.0.0.1',
      port: 9000,
      rules: rules,
    },
  });

  try {
    const aliceContext = testEnv.authenticatedContext('alice_123');
    const bobContext = testEnv.authenticatedContext('bob_456');
    const unauthContext = testEnv.unauthenticatedContext();

    const aliceDb = aliceContext.database();
    const bobDb = bobContext.database();
    const unauthDb = unauthContext.database();

    // Setup: Create room by Alice (host)
    console.log('[Test Setup] Creating room by Alice...');
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.database();
      await adminDb.ref('rooms/room_test_1').set({
        hostUid: 'alice_123',
        name: 'Ruang Belajar Alice',
        status: 'berjalan',
      });
      await adminDb.ref('roomMembers/room_test_1/alice_123').set({
        uid: 'alice_123',
        name: 'Alice',
        isHost: true,
      });
      await adminDb.ref('roomCodes/KRK-TEST').set({
        roomId: 'room_test_1',
        active: true,
      });
    });

    // TEST 1: Codes cannot be enumerated (no listing)
    console.log('[Test 1] Testing: codes cannot be enumerated...');
    await assertFails(aliceDb.ref('roomCodes').get());
    await assertFails(unauthDb.ref('roomCodes').get());
    console.log('  PASS: Listing roomCodes is blocked.');

    // Reading specific exact code is allowed for authenticated users
    await assertSucceeds(aliceDb.ref('roomCodes/KRK-TEST').get());
    console.log('  PASS: Reading exact code KRK-TEST is allowed for signed-in users.');

    // TEST 2: A non-member cannot read a room
    console.log('[Test 2] Testing: non-member cannot read a room...');
    // Bob is not a member of room_test_1
    await assertFails(bobDb.ref('rooms/room_test_1').get());
    await assertFails(bobDb.ref('roomMembers/room_test_1').get());
    console.log('  PASS: Non-member Bob is denied reading room_test_1 and roomMembers.');

    // Alice is a member, so Alice can read
    await assertSucceeds(aliceDb.ref('rooms/room_test_1').get());
    await assertSucceeds(aliceDb.ref('roomMembers/room_test_1').get());
    console.log('  PASS: Member Alice can read room_test_1 and roomMembers.');

    // TEST 3: A user cannot write an event with another uid
    console.log('[Test 3] Testing: a user cannot write an event with another uid...');
    // Alice tries to write event with Bob's UID -> MUST FAIL
    await assertFails(
      aliceDb.ref('roomEvents/room_test_1/evt_fake').set({
        type: 'violation',
        uid: 'bob_456', // FAKED UID
        deltaTiltDeg: 25.0,
      })
    );
    console.log('  PASS: Alice writing event with Bob UID is blocked.');

    // Alice writing event with her own UID ('alice_123') -> MUST SUCCEED
    await assertSucceeds(
      aliceDb.ref('roomEvents/room_test_1/evt_alice').set({
        type: 'violation',
        uid: 'alice_123', // REAL UID
        deltaTiltDeg: 25.0,
      })
    );
    console.log('  PASS: Alice writing event with her own UID succeeds.');

    // Event cannot be edited or deleted
    await assertFails(
      aliceDb.ref('roomEvents/room_test_1/evt_alice').update({
        deltaTiltDeg: 10.0,
      })
    );
    await assertFails(aliceDb.ref('roomEvents/room_test_1/evt_alice').remove());
    console.log('  PASS: Event cannot be edited or deleted.');

    console.log('\n>>> ALL 3 SECURITY RULES TESTS PASSED SUCCESSFULLY! <<<');
  } finally {
    await testEnv.cleanup();
  }
}

runTests().catch((err) => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
