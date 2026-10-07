import {randomInt, randomUUID} from "node:crypto";
import {initializeApp} from "firebase-admin/app";
import {
  FieldValue,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {setGlobalOptions} from "firebase-functions/v2";
import {
  CallableRequest,
  HttpsError,
  onCall,
} from "firebase-functions/v2/https";
import {onDocumentCreated} from "firebase-functions/v2/firestore";

initializeApp();
const db = getFirestore();

setGlobalOptions({
  region: "asia-southeast1",
  maxInstances: 10,
  memory: "256MiB",
  timeoutSeconds: 30,
});

type JsonMap = Record<string, unknown>;

const EVENT_TYPES = new Set([
  "suspected_use",
  "monitoring_interrupted",
  "allowed_use",
]);

function requireUid(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Pengguna belum terautentikasi.");
  }
  return uid;
}

function requireMap(value: unknown): JsonMap {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new HttpsError("invalid-argument", "Payload harus berupa object.");
  }
  return value as JsonMap;
}

function requireString(
  data: JsonMap,
  key: string,
  min: number,
  max: number,
): string {
  const value = data[key];
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${key} harus berupa string.`);
  }
  const cleaned = value.trim();
  if (cleaned.length < min || cleaned.length > max) {
    throw new HttpsError(
      "invalid-argument",
      `${key} harus memiliki ${min}-${max} karakter.`,
    );
  }
  return cleaned;
}

function requireId(data: JsonMap, key: string): string {
  const value = requireString(data, key, 5, 128);
  if (!/^[A-Za-z0-9_-]+$/.test(value)) {
    throw new HttpsError(
      "invalid-argument",
      `${key} hanya boleh berisi huruf, angka, garis bawah, dan tanda hubung.`,
    );
  }
  return value;
}

function optionalString(
  data: JsonMap,
  key: string,
  fallback: string,
  max: number,
): string {
  const value = data[key];
  if (typeof value !== "string" || value.trim().length === 0) return fallback;
  return value.trim().slice(0, max);
}

function boundedNumber(
  value: unknown,
  fallback: number,
  min: number,
  max: number,
): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return fallback;
  return Math.min(max, Math.max(min, value));
}

function requireNumber(
  data: JsonMap,
  key: string,
  min: number,
  max: number,
): number {
  const value = data[key];
  if (typeof value !== "number" || !Number.isFinite(value) ||
      value < min || value > max) {
    throw new HttpsError(
      "invalid-argument",
      `${key} harus berupa angka pada rentang ${min}-${max}.`,
    );
  }
  return value;
}

function normalizeCode(value: string): string {
  return value.toUpperCase().replace(/[^A-Z0-9]/g, "");
}

function generateRoomCode(): string {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let result = "";
  for (let i = 0; i < 6; i += 1) {
    result += alphabet[randomInt(0, alphabet.length)];
  }
  return result;
}

function sanitizeEvidence(value: unknown): Record<string, number> {
  const input = value && typeof value === "object" && !Array.isArray(value) ?
    value as JsonMap : {};
  return {
    peakGyro: boundedNumber(input.peakGyro, 0, 0, 50),
    rmsGyro: boundedNumber(input.rmsGyro, 0, 0, 50),
    peakAccel: boundedNumber(input.peakAccel, 0, 0, 100),
    orientationChangeDeg: boundedNumber(
      input.orientationChangeDeg,
      0,
      0,
      360,
    ),
    confidence: boundedNumber(input.confidence, 0, 0, 1),
  };
}

async function saveUser(uid: string, displayName: string): Promise<void> {
  const userRef = db.doc(`users/${uid}`);
  const userSnapshot = await userRef.get();
  await userRef.set({
    displayName,
    updatedAt: FieldValue.serverTimestamp(),
    ...(!userSnapshot.exists ? {createdAt: FieldValue.serverTimestamp()} : {}),
  }, {merge: true});
}

export const createRoom = onCall(async (request) => {
  const uid = requireUid(request);
  const data = requireMap(request.data);
  const displayName = requireString(data, "displayName", 2, 40);
  const title = optionalString(data, "title", "Sesi Belajar Kelompok", 80);
  const durationMinutes = Math.round(boundedNumber(
    data.durationMinutes,
    30,
    5,
    180,
  ));

  await saveUser(uid, displayName);

  for (let attempt = 0; attempt < 8; attempt += 1) {
    const roomId = db.collection("rooms").doc().id;
    const code = generateRoomCode();
    const roomRef = db.doc(`rooms/${roomId}`);
    const codeRef = db.doc(`roomCodes/${code}`);
    const memberRef = roomRef.collection("members").doc(uid);

    try {
      await db.runTransaction(async (tx) => {
        const codeSnapshot = await tx.get(codeRef);
        if (codeSnapshot.exists) throw new Error("ROOM_CODE_COLLISION");

        tx.set(codeRef, {
          roomId,
          createdAt: FieldValue.serverTimestamp(),
        });
        tx.set(roomRef, {
          code,
          title,
          leaderId: uid,
          durationMinutes,
          state: "waiting",
          currentSessionId: null,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        tx.set(memberRef, {
          displayName,
          role: "leader",
          active: true,
          distractionCount: 0,
          joinedAt: FieldValue.serverTimestamp(),
          lastDistractionAt: null,
        });
      });

      return {roomId, code, title, durationMinutes};
    } catch (error) {
      if (error instanceof Error && error.message === "ROOM_CODE_COLLISION") {
        continue;
      }
      throw error;
    }
  }

  throw new HttpsError("aborted", "Gagal membuat kode room unik. Coba lagi.");
});

export const joinRoom = onCall(async (request) => {
  const uid = requireUid(request);
  const data = requireMap(request.data);
  const displayName = requireString(data, "displayName", 2, 40);
  const code = normalizeCode(requireString(data, "code", 6, 12));
  if (code.length !== 6) {
    throw new HttpsError("invalid-argument", "Kode room harus 6 karakter.");
  }

  const codeRef = db.doc(`roomCodes/${code}`);
  let result: JsonMap = {};

  await db.runTransaction(async (tx) => {
    const codeSnapshot = await tx.get(codeRef);
    if (!codeSnapshot.exists) {
      throw new HttpsError("not-found", "Room tidak ditemukan.");
    }

    const roomId = String(codeSnapshot.get("roomId"));
    const roomRef = db.doc(`rooms/${roomId}`);
    const roomSnapshot = await tx.get(roomRef);
    if (!roomSnapshot.exists || roomSnapshot.get("state") === "finished") {
      throw new HttpsError("failed-precondition", "Room sudah ditutup.");
    }

    tx.set(roomRef.collection("members").doc(uid), {
      displayName,
      role: roomSnapshot.get("leaderId") === uid ? "leader" : "member",
      active: true,
      distractionCount: 0,
      joinedAt: FieldValue.serverTimestamp(),
      lastDistractionAt: null,
    }, {merge: true});

    result = {
      roomId,
      code,
      title: roomSnapshot.get("title"),
      durationMinutes: roomSnapshot.get("durationMinutes"),
      state: roomSnapshot.get("state"),
      currentSessionId: roomSnapshot.get("currentSessionId") ?? null,
    };
  });

  await saveUser(uid, displayName);
  return result;
});

export const leaveRoom = onCall(async (request) => {
  const uid = requireUid(request);
  const data = requireMap(request.data);
  const roomId = requireId(data, "roomId");
  const roomRef = db.doc(`rooms/${roomId}`);
  const memberRef = roomRef.collection("members").doc(uid);
  await db.runTransaction(async (tx) => {
    const [room, member] = await Promise.all([tx.get(roomRef), tx.get(memberRef)]);
    if (!room.exists || !member.exists) return;
    // The leader retains membership so the room can still be closed.
    if (room.get("leaderId") !== uid) tx.update(memberRef, {active: false});
  });
  return {ok: true};
});

export const startSession = onCall(async (request) => {
  const uid = requireUid(request);
  const data = requireMap(request.data);
  const roomId = requireId(data, "roomId");
  const roomRef = db.doc(`rooms/${roomId}`);
  const sessionId = randomUUID();
  const sessionRef = roomRef.collection("sessions").doc(sessionId);
  let result: JsonMap = {};

  await db.runTransaction(async (tx) => {
    const roomSnapshot = await tx.get(roomRef);
    if (!roomSnapshot.exists) {
      throw new HttpsError("not-found", "Room tidak ditemukan.");
    }
    if (roomSnapshot.get("leaderId") !== uid) {
      throw new HttpsError("permission-denied", "Hanya ketua yang dapat memulai sesi.");
    }
    if (roomSnapshot.get("state") === "active") {
      result = {
        sessionId: roomSnapshot.get("currentSessionId"),
        alreadyActive: true,
      };
      return;
    }
    if (roomSnapshot.get("state") === "finished") {
      throw new HttpsError("failed-precondition", "Room sudah ditutup.");
    }

    const durationMinutes = Number(roomSnapshot.get("durationMinutes"));
    const startedAt = Timestamp.now();
    const endsAt = Timestamp.fromMillis(
      startedAt.toMillis() + durationMinutes * 60_000,
    );

    tx.create(sessionRef, {
      state: "active",
      leaderId: uid,
      durationMinutes,
      startedAt,
      endsAt,
      endedAt: null,
    });
    tx.update(roomRef, {
      state: "active",
      currentSessionId: sessionId,
      updatedAt: FieldValue.serverTimestamp(),
    });
    result = {sessionId, alreadyActive: false, endsAtMs: endsAt.toMillis()};
  });

  return result;
});

export const endSession = onCall(async (request) => {
  const uid = requireUid(request);
  const data = requireMap(request.data);
  const roomId = requireId(data, "roomId");
  const sessionId = requireId(data, "sessionId");
  const roomRef = db.doc(`rooms/${roomId}`);
  const sessionRef = roomRef.collection("sessions").doc(sessionId);

  await db.runTransaction(async (tx) => {
    const [roomSnapshot, sessionSnapshot] = await Promise.all([
      tx.get(roomRef),
      tx.get(sessionRef),
    ]);
    if (!roomSnapshot.exists || !sessionSnapshot.exists) {
      throw new HttpsError("not-found", "Room atau sesi tidak ditemukan.");
    }
    if (roomSnapshot.get("leaderId") !== uid) {
      throw new HttpsError("permission-denied", "Hanya ketua yang dapat mengakhiri sesi.");
    }
    if (roomSnapshot.get("currentSessionId") !== sessionId) {
      throw new HttpsError("failed-precondition", "Sesi bukan sesi aktif room.");
    }

    tx.update(sessionRef, {
      state: "ended",
      endedAt: FieldValue.serverTimestamp(),
    });
    tx.update(roomRef, {
      state: "finished",
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return {ok: true};
});

export const submitFocusEvent = onCall(async (request) => {
  const uid = requireUid(request);
  const data = requireMap(request.data);
  const roomId = requireId(data, "roomId");
  const sessionId = requireId(data, "sessionId");
  const eventId = requireId(data, "eventId");
  const episodeId = requireId(data, "episodeId");
  const type = requireString(data, "type", 3, 40);
  const ruleVersion = optionalString(data, "ruleVersion", "unknown", 40);
  const calibrationVersion = optionalString(
    data,
    "calibrationVersion",
    "unknown",
    40,
  );

  if (!EVENT_TYPES.has(type)) {
    throw new HttpsError("invalid-argument", "Tipe event tidak didukung.");
  }

  const nowMs = Date.now();
  const observedAtMs = Math.round(requireNumber(
    data,
    "observedAtMs",
    nowMs - 24 * 60 * 60 * 1000,
    nowMs + 5_000,
  ));
  const durationMs = Math.round(requireNumber(
    data,
    "durationMs",
    250,
    120_000,
  ));
  const evidence = sanitizeEvidence(data.evidence);
  const liveEligible = type === "suspected_use" && nowMs - observedAtMs <= 30_000;

  const roomRef = db.doc(`rooms/${roomId}`);
  const sessionRef = roomRef.collection("sessions").doc(sessionId);
  const memberRef = roomRef.collection("members").doc(uid);
  const eventRef = sessionRef.collection("events").doc(eventId);
  const lockId = `${uid}_${episodeId}`;
  const lockRef = sessionRef.collection("episodeLocks").doc(lockId);
  const presenceRef = sessionRef.collection("presence").doc(uid);
  let duplicate = false;

  await db.runTransaction(async (tx) => {
    const [roomSnapshot, sessionSnapshot, memberSnapshot, eventSnapshot, lockSnapshot] =
      await Promise.all([
        tx.get(roomRef),
        tx.get(sessionRef),
        tx.get(memberRef),
        tx.get(eventRef),
        tx.get(lockRef),
      ]);

    if (eventSnapshot.exists || lockSnapshot.exists) {
      duplicate = true;
      return;
    }
    if (!roomSnapshot.exists || !sessionSnapshot.exists || !memberSnapshot.exists) {
      throw new HttpsError("not-found", "Room, sesi, atau anggota tidak ditemukan.");
    }
    if (roomSnapshot.get("state") !== "active" ||
        roomSnapshot.get("currentSessionId") !== sessionId ||
        sessionSnapshot.get("state") !== "active") {
      throw new HttpsError("failed-precondition", "Sesi sudah tidak aktif.");
    }
    if (memberSnapshot.get("active") !== true) {
      throw new HttpsError("permission-denied", "Keanggotaan tidak aktif.");
    }

    const actorName = String(memberSnapshot.get("displayName") ?? "Anggota");
    tx.create(lockRef, {
      eventId,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.create(eventRef, {
      episodeId,
      actorUid: uid,
      actorName,
      type,
      observedAt: Timestamp.fromMillis(observedAtMs),
      receivedAt: FieldValue.serverTimestamp(),
      durationMs,
      evidence,
      ruleVersion,
      calibrationVersion,
      liveEligible,
      notificationState: liveEligible ? "pending" : "history_only",
    });
    tx.set(presenceRef, {
      state: type,
      heartbeatAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    if (type === "suspected_use") {
      tx.update(memberRef, {
        distractionCount: FieldValue.increment(1),
        lastDistractionAt: FieldValue.serverTimestamp(),
      });
    }
  });

  return {ok: true, duplicate, liveEligible};
});

interface DeviceToken {
  token: string;
  refPath: string;
}

async function getRoomTokens(roomId: string, actorUid: string): Promise<DeviceToken[]> {
  const members = await db.collection(`rooms/${roomId}/members`)
    .where("active", "==", true)
    .get();
  const deviceSnapshots = await Promise.all(
    members.docs
      .filter((member) => member.id !== actorUid)
      .map((member) => db.collection(`users/${member.id}/devices`).get()),
  );

  const unique = new Map<string, DeviceToken>();
  for (const snapshot of deviceSnapshots) {
    for (const document of snapshot.docs) {
      const token = document.get("token");
      if (typeof token === "string" && token.length > 20) {
        unique.set(token, {token, refPath: document.ref.path});
      }
    }
  }
  return [...unique.values()];
}

export const notifyFocusEvent = onDocumentCreated(
  "rooms/{roomId}/sessions/{sessionId}/events/{eventId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const data = snapshot.data();
    if (data.type !== "suspected_use" || data.liveEligible !== true ||
        data.notificationState !== "pending") {
      return;
    }

    const roomId = event.params.roomId;
    const sessionId = event.params.sessionId;
    const eventId = event.params.eventId;
    const actorUid = String(data.actorUid);
    const actorName = String(data.actorName ?? "Seorang anggota");
    const devices = await getRoomTokens(roomId, actorUid);
    if (devices.length === 0) {
      await snapshot.ref.update({
        notificationState: "no_recipients",
        notificationFinishedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    let successCount = 0;
    let failureCount = 0;
    const invalidTokenPaths: string[] = [];

    for (let offset = 0; offset < devices.length; offset += 500) {
      const batch = devices.slice(offset, offset + 500);
      const response = await getMessaging().sendEachForMulticast({
        tokens: batch.map((item) => item.token),
        notification: {
          title: "Indikasi penggunaan HP",
          body: `${actorName} terdeteksi memindahkan atau menggunakan HP.`,
        },
        data: {
          type: "focus_event",
          roomId,
          sessionId,
          eventId,
          actorUid,
        },
        android: {priority: "high"},
      });
      successCount += response.successCount;
      failureCount += response.failureCount;

      response.responses.forEach((item, index) => {
        const code = item.error?.code;
        if (code === "messaging/registration-token-not-registered" ||
            code === "messaging/invalid-registration-token") {
          invalidTokenPaths.push(batch[index].refPath);
        }
      });
    }

    if (invalidTokenPaths.length > 0) {
      const deleteBatch = db.batch();
      invalidTokenPaths.forEach((path) => deleteBatch.delete(db.doc(path)));
      await deleteBatch.commit();
    }

    await snapshot.ref.update({
      notificationState: "sent",
      notificationSuccessCount: successCount,
      notificationFailureCount: failureCount,
      notificationFinishedAt: FieldValue.serverTimestamp(),
    });
  },
);
