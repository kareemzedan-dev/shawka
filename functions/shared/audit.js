const { FieldValue } = require("firebase-admin/firestore");

/**
 * Write audit_logs entry — §11.1 / admin ops.
 */
async function writeAuditLog(db, {
  type,
  actorUid,
  actorRole,
  targetType,
  targetId,
  details = {},
  severity = "info",
}) {
  await db.collection("audit_logs").add({
    type,
    actorUid: actorUid || null,
    actorRole: actorRole || null,
    targetType,
    targetId,
    details,
    severity,
    createdAt: FieldValue.serverTimestamp(),
  });
}

module.exports = { writeAuditLog };
