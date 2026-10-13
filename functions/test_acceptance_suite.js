const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

async function runAcceptanceTests() {
  console.log('===============================================================');
  console.log('--- Phase A9: Firebase Realtime Database Acceptance Test Suite ---');
  console.log('===============================================================\n');

  const rulesPath = path.resolve(__dirname, '../database.rules.json');
  const rules = fs.readFileSync(rulesPath, 'utf8');

  const testEnv = await initializeTestEnvironment({
    projectId: 'demo-kerkom-acceptance-test',
    database: {
      host: '127.0.0.1',
      port: 9000,
      rules: rules,
    },
  });

  let totalTests = 0;
  let passedTests = 0;

  async function check(name, testFn) {
    totalTests++;
    try {
      await testFn();
      passedTests++;
      console.log(`[PASS] (${totalTests}) ${name}`);
    } catch (err) {
      console.error(`[FAIL] (${totalTests}) ${name}`);
      console.error('       Error:', err.message || err);
      throw err;
    }
  }

  try {
    const aliceContext = testEnv.authenticatedContext('alice_uid');
    const bobContext = testEnv.authenticatedContext('bob_uid');
    const charlieContext = testEnv.authenticatedContext('charlie_uid');
    const unauthContext = testEnv.unauthenticatedContext();

    const aliceDb = aliceContext.database();
    const bobDb = bobContext.database();
    const charlieDb = charlieContext.database();
    const unauthDb = unauthContext.database();

    // -----------------------------------------------------------------
    // 1. Users Security & Visibility
    // -----------------------------------------------------------------
    console.log('\n--- 1. Users Security & Field-Level Visibility ---');

    await check('users/{uid} writable only by owner', async () => {
      // Alice can write her own profile
      await assertSucceeds(
        aliceDb.ref('users/alice_uid').set({
          displayName: 'Alice In Wonderland',
          photoUrl: 'https://example.com/alice.png',
          email: 'alice@kerkom.app',
          settings: { tiltToleranceDeg: 15, alarmMode: 'both' }
        })
      );
      // Bob cannot write Alice's profile
      await assertFails(
        bobDb.ref('users/alice_uid').set({
          displayName: 'Hacked By Bob'
        })
      );
    });

    await check('users/{uid} private fields non-readable by other users', async () => {
      // Bob cannot read Alice's entire profile root (which contains email & settings)
      await assertFails(bobDb.ref('users/alice_uid').get());
      // Alice can read her own profile root
      await assertSucceeds(aliceDb.ref('users/alice_uid').get());
    });

    await check('users/{uid}/displayName & photoUrl readable by other signed-in users', async () => {
      // Bob can read Alice's displayName and photoUrl
      await assertSucceeds(bobDb.ref('users/alice_uid/displayName').get());
      await assertSucceeds(bobDb.ref('users/alice_uid/photoUrl').get());
      // Unauthenticated cannot read displayName
      await assertFails(unauthDb.ref('users/alice_uid/displayName').get());
    });

    // -----------------------------------------------------------------
    // 2. Room Codes Non-Enumeration & Lookup
    // -----------------------------------------------------------------
    console.log('\n--- 2. Room Codes Non-Enumeration & Exact Lookup ---');

    await check('roomCodes root cannot be listed / enumerated (no listing)', async () => {
      await assertFails(aliceDb.ref('roomCodes').get());
      await assertFails(bobDb.ref('roomCodes').get());
      await assertFails(unauthDb.ref('roomCodes').get());
    });

    // Setup room & code by Alice (host)
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.database();
      await adminDb.ref('rooms/room_mvp_1').set({
        hostUid: 'alice_uid',
        name: 'Kerkom Algoritma Lanjut',
        status: 'lobi',
        memberCount: 2,
        createdAt: 1700000000
      });
      await adminDb.ref('roomMembers/room_mvp_1/alice_uid').set({
        uid: 'alice_uid',
        name: 'Alice',
        isHost: true,
        state: 'aman'
      });
      await adminDb.ref('roomMembers/room_mvp_1/bob_uid').set({
        uid: 'bob_uid',
        name: 'Bob',
        isHost: false,
        state: 'aman'
      });
      await adminDb.ref('roomCodes/KRK-7K2Q').set({
        roomId: 'room_mvp_1',
        active: true
      });
    });

    await check('roomCodes/{code} readable by exact code for authenticated users', async () => {
      await assertSucceeds(aliceDb.ref('roomCodes/KRK-7K2Q').get());
      await assertSucceeds(bobDb.ref('roomCodes/KRK-7K2Q').get());
      await assertSucceeds(charlieDb.ref('roomCodes/KRK-7K2Q').get());
      await assertFails(unauthDb.ref('roomCodes/KRK-7K2Q').get());
    });

    // -----------------------------------------------------------------
    // 3. Room & Member Access Controls
    // -----------------------------------------------------------------
    console.log('\n--- 3. Room & Member Access Controls ---');

    await check('Non-member Charlie cannot read room_mvp_1 or its roomMembers', async () => {
      await assertFails(charlieDb.ref('rooms/room_mvp_1').get());
      await assertFails(charlieDb.ref('roomMembers/room_mvp_1').get());
    });

    await check('Members Alice and Bob can read room_mvp_1 and roomMembers', async () => {
      await assertSucceeds(aliceDb.ref('rooms/room_mvp_1').get());
      await assertSucceeds(aliceDb.ref('roomMembers/room_mvp_1').get());
      await assertSucceeds(bobDb.ref('rooms/room_mvp_1').get());
      await assertSucceeds(bobDb.ref('roomMembers/room_mvp_1').get());
    });

    await check('Host Alice can change room status; non-host Bob cannot', async () => {
      // Alice changes status to 'kalibrasi' -> SUCCEED
      await assertSucceeds(
        aliceDb.ref('rooms/room_mvp_1').update({
          status: 'kalibrasi'
        })
      );
      // Bob tries to change status to 'selesai' -> FAIL
      await assertFails(
        bobDb.ref('rooms/room_mvp_1').update({
          status: 'selesai'
        })
      );
    });

    await check('roomMembers/{roomId}/{uid} writable only by that uid', async () => {
      // Bob updates his own state to 'terangkat' -> SUCCEED
      await assertSucceeds(
        bobDb.ref('roomMembers/room_mvp_1/bob_uid').update({
          state: 'terangkat',
          liftCount: 1
        })
      );
      // Bob cannot update Alice's member state -> FAIL
      await assertFails(
        bobDb.ref('roomMembers/room_mvp_1/alice_uid').update({
          state: 'terangkat'
        })
      );
    });

    // -----------------------------------------------------------------
    // 4. Technical Cap of 50 Members per Room
    // -----------------------------------------------------------------
    console.log('\n--- 4. Technical Cap of 50 Members per Room ---');

    await check('Member join allowed when room memberCount < 50', async () => {
      // Charlie joins room_mvp_1 (currently memberCount = 2)
      await assertSucceeds(
        charlieDb.ref('roomMembers/room_mvp_1/charlie_uid').set({
          uid: 'charlie_uid',
          name: 'Charlie',
          isHost: false,
          state: 'aman'
        })
      );
    });

    await check('Member join rejected when room memberCount reaches technical cap 50', async () => {
      // Set memberCount = 50 in admin mode
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.database();
        await adminDb.ref('rooms/room_full_50').set({
          hostUid: 'alice_uid',
          name: 'Ruang Penuh',
          status: 'lobi',
          memberCount: 50
        });
      });

      const daveContext = testEnv.authenticatedContext('dave_uid');
      const daveDb = daveContext.database();

      // Dave attempts to join room_full_50 -> MUST FAIL due to .validate memberCount < 50
      await assertFails(
        daveDb.ref('roomMembers/room_full_50/dave_uid').set({
          uid: 'dave_uid',
          name: 'Dave',
          isHost: false,
          state: 'aman'
        })
      );
    });

    // -----------------------------------------------------------------
    // 5. Room Events Security & Immutability
    // -----------------------------------------------------------------
    console.log('\n--- 5. Room Events Security & Immutability ---');

    await check('Member cannot create event with another user UID', async () => {
      // Bob tries to create event pretending to be Alice
      await assertFails(
        bobDb.ref('roomEvents/room_mvp_1/evt_fake').set({
          type: 'violation',
          uid: 'alice_uid',
          deltaTiltDeg: 20.0,
          zScore: 7.0
        })
      );
    });

    await check('Member can create event with their own UID', async () => {
      // Bob writes his own event
      await assertSucceeds(
        bobDb.ref('roomEvents/room_mvp_1/evt_bob_1').set({
          type: 'violation',
          uid: 'bob_uid',
          deltaTiltDeg: 24.5,
          zScore: 6.8
        })
      );
    });

    await check('Room events are strictly immutable (no update, no delete)', async () => {
      // Bob cannot update his past event
      await assertFails(
        bobDb.ref('roomEvents/room_mvp_1/evt_bob_1').update({
          deltaTiltDeg: 5.0
        })
      );
      // Bob cannot delete his past event
      await assertFails(bobDb.ref('roomEvents/room_mvp_1/evt_bob_1').remove());
      // Alice (host) also cannot delete events
      await assertFails(aliceDb.ref('roomEvents/room_mvp_1/evt_bob_1').remove());
    });

    // -----------------------------------------------------------------
    // 6. User Sessions & Active Room Node Isolation
    // -----------------------------------------------------------------
    console.log('\n--- 6. User Sessions & Active Room Node Isolation ---');

    await check('userSessions/{uid} readable and writable only by owner', async () => {
      // Alice writes her session record
      await assertSucceeds(
        aliceDb.ref('userSessions/alice_uid/session_1').set({
          roomId: 'room_mvp_1',
          roomName: 'Kerkom Algoritma Lanjut',
          startAt: 1700000000,
          durationDoneMin: 45,
          violationCount: 0,
          endedHow: 'timer'
        })
      );
      // Alice reads her session
      await assertSucceeds(aliceDb.ref('userSessions/alice_uid').get());
      // Bob cannot read Alice's userSessions
      await assertFails(bobDb.ref('userSessions/alice_uid').get());
      // Bob cannot write to Alice's userSessions
      await assertFails(
        bobDb.ref('userSessions/alice_uid/session_fake').set({
          roomName: 'Fake'
        })
      );
    });

    await check('userActiveRoom/{uid} readable and writable only by owner', async () => {
      await assertSucceeds(
        aliceDb.ref('userActiveRoom/alice_uid').set({
          roomId: 'room_mvp_1'
        })
      );
      await assertSucceeds(aliceDb.ref('userActiveRoom/alice_uid').get());
      await assertFails(bobDb.ref('userActiveRoom/alice_uid').get());
      await assertFails(
        bobDb.ref('userActiveRoom/alice_uid').set({
          roomId: 'room_hacked'
        })
      );
    });

    console.log('\n===============================================================');
    console.log(`>>> ACCEPTANCE TEST SUMMARY: ${passedTests}/${totalTests} TESTS PASSED (100%) <<<`);
    console.log('===============================================================');
  } finally {
    await testEnv.cleanup();
  }
}

runAcceptanceTests().catch((err) => {
  console.error('\nAcceptance test suite failed with error:', err);
  process.exit(1);
});
