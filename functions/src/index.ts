import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";

import { initializeApp } from "firebase-admin/app";

// Initialize Firebase Admin SDK
initializeApp();

const db = getFirestore();

// Types for better type safety
interface TrackingSession {
  id: string;
  userId: string;
  startTime: Timestamp;
  endTime?: Timestamp;
  durationInSeconds: number;
  miles: number;
  earnings?: number;
  expenses?: number;
  locations: LocationPoint[];
  isActive: boolean;
}

interface LocationPoint {
  latitude: number;
  longitude: number;
  timestamp: Timestamp;
}

interface PeriodInsights {
  totalMiles: number;
  totalDurationInSeconds: number;
  totalEarnings: number;
  totalExpenses: number;
  sessionCount: number;
  periodStart: Timestamp;
  periodEnd: Timestamp;
}

interface ValidationMeta {
  lastValidated: Timestamp;
  lastValidatedPeriod: string;
  needsValidation: boolean;
  consecutiveSuccessfulValidations: number;
}

interface UserInsightSummary {
  userId: string;
  today: PeriodInsights;
  thisWeek: PeriodInsights;
  thisMonth: PeriodInsights;
  thisYear: PeriodInsights;
  lastUpdated: Timestamp;
  version: number;
  validation: ValidationMeta;
}

interface SessionInsight {
  totalMiles: number;
  totalDurationInSeconds: number;
  totalEarnings: number;
  totalExpenses: number;
  sessionCount: number;
}

interface PendingUpdate {
  userId: string;
  sessionId: string;
  sessionData: Record<string, any>;
  updateType: "CREATE" | "UPDATE" | "DELETE";
  timestamp: Timestamp;
  retryCount: number;
  error: string;
  status: "pending" | "completed" | "failed";
}

type UpdateType = "CREATE" | "UPDATE" | "DELETE";

/**
 * Cloud Function triggered when tracking session is created/updated/deleted
 * Maintains insight summary in real-time
 */
export const updateInsightSummary = onDocumentWritten(
  "users/{userId}/tracking_sessions/{sessionId}",
  async (event) => {
    const { userId, sessionId } = event.params;

    const before = event.data?.before?.exists
      ? (event.data.before.data() as TrackingSession)
      : null;
    const after = event.data?.after?.exists
      ? (event.data.after.data() as TrackingSession)
      : null;

    // Determine update type
    let updateType: UpdateType;
    if (!before && after) {
      updateType = "CREATE";
    } else if (before && after) {
      updateType = "UPDATE";
    } else if (before && !after) {
      updateType = "DELETE";
    } else {
      return; // No change
    }

    try {
      await updateSummaryWithRetry(
        userId,
        before,
        after,
        updateType,
        sessionId
      );

      logger.info(
        `Successfully updated insight summary for user ${userId}, session ${sessionId}, type: ${updateType}`
      );
    } catch (error) {
      logger.error(
        `Failed to update insight summary for user ${userId}:`,
        error
      );

      // Store failed update for retry
      await storePendingUpdate(
        userId,
        sessionId,
        after || {},
        updateType,
        (error as Error).message
      );
    }
  }
);

/**
 * Retry logic for concurrent updates with exponential backoff
 */
async function updateSummaryWithRetry(
  userId: string,
  beforeSession: TrackingSession | null,
  afterSession: TrackingSession | null,
  updateType: UpdateType,
  sessionId: string,
  maxRetries: number = 3
): Promise<void> {
  let retryCount = 0;

  while (retryCount < maxRetries) {
    try {
      await db.runTransaction(async (transaction) => {
        const summaryRef = db.collection("insight-summary").doc(userId);
        const summaryDoc = await transaction.get(summaryRef);

        let currentSummary: UserInsightSummary;
        if (!summaryDoc.exists) {
          currentSummary = createEmptySummary(userId);
        } else {
          currentSummary = summaryDoc.data() as UserInsightSummary;
        }

        // Calculate new summary
        const updatedSummary = calculateUpdatedSummary(
          currentSummary,
          beforeSession,
          afterSession,
          updateType
        );

        // Increment version for optimistic locking
        updatedSummary.version = (currentSummary.version || 0) + 1;
        updatedSummary.lastUpdated = Timestamp.now();

        transaction.set(summaryRef, updatedSummary, { merge: true });
      });

      return; // Success, exit retry loop
    } catch (error: any) {
      retryCount++;

      if (error.code === "aborted" && retryCount < maxRetries) {
        // Transaction conflict, retry with exponential backoff
        await new Promise((resolve) =>
          setTimeout(resolve, Math.pow(2, retryCount) * 100)
        );
        continue;
      }

      throw error; // Re-throw if not retryable or max retries reached
    }
  }

  throw new Error(`Failed to update summary after ${maxRetries} retries`);
}

/**
 * Calculate updated summary based on session changes
 */
function calculateUpdatedSummary(
  currentSummary: UserInsightSummary,
  beforeSession: TrackingSession | null,
  afterSession: TrackingSession | null,
  updateType: UpdateType
): UserInsightSummary {
  const now = new Date();
  const summary = { ...currentSummary };

  // Helper function to get period boundaries
  const getPeriodBoundaries = (date: Date) => {
    return {
      today: getToday(date),
      weekStart: getWeekStart(date),
      monthStart: getMonthStart(date),
      yearStart: getYearStart(date),
    };
  };

  // Handle before session (subtract if UPDATE or DELETE)
  if (beforeSession && (updateType === "UPDATE" || updateType === "DELETE")) {
    const beforeBoundaries = getPeriodBoundaries(
      beforeSession.startTime.toDate()
    );
    subtractSessionFromSummary(summary, beforeSession, beforeBoundaries, now);
  }

  // Handle after session (add if CREATE or UPDATE)
  if (afterSession && (updateType === "CREATE" || updateType === "UPDATE")) {
    const afterBoundaries = getPeriodBoundaries(
      afterSession.startTime.toDate()
    );
    addSessionToSummary(summary, afterSession, afterBoundaries, now);
  }

  return summary;
}

/**
 * Add session data to summary
 */
function addSessionToSummary(
  summary: UserInsightSummary,
  session: TrackingSession,
  boundaries: ReturnType<typeof getPeriodBoundaries>,
  now: Date
): void {
  const sessionInsight = createSessionInsight(session);
  const sessionDate = session.startTime.toDate();

  // Add to appropriate periods using session date
  if (isInPeriod(sessionDate, now, "day")) {
    summary.today = addInsights(
      summary.today || createEmptyPeriod(boundaries.today),
      sessionInsight
    );
  }

  if (isInPeriod(sessionDate, now, "week")) {
    summary.thisWeek = addInsights(
      summary.thisWeek || createEmptyPeriod(boundaries.weekStart),
      sessionInsight
    );
  }

  if (isInPeriod(sessionDate, now, "month")) {
    summary.thisMonth = addInsights(
      summary.thisMonth || createEmptyPeriod(boundaries.monthStart),
      sessionInsight
    );
  }

  if (isInPeriod(sessionDate, now, "year")) {
    summary.thisYear = addInsights(
      summary.thisYear || createEmptyPeriod(boundaries.yearStart),
      sessionInsight
    );
  }
}

/**
 * Subtract session data from summary
 */
function subtractSessionFromSummary(
  summary: UserInsightSummary,
  session: TrackingSession,
  boundaries: ReturnType<typeof getPeriodBoundaries>,
  now: Date
): void {
  const sessionInsight = createSessionInsight(session);
  const sessionDate = session.startTime.toDate();

  // Subtract from appropriate periods using session date
  if (isInPeriod(sessionDate, now, "day")) {
    summary.today = subtractInsights(
      summary.today || createEmptyPeriod(boundaries.today),
      sessionInsight
    );
  }

  if (isInPeriod(sessionDate, now, "week")) {
    summary.thisWeek = subtractInsights(
      summary.thisWeek || createEmptyPeriod(boundaries.weekStart),
      sessionInsight
    );
  }

  if (isInPeriod(sessionDate, now, "month")) {
    summary.thisMonth = subtractInsights(
      summary.thisMonth || createEmptyPeriod(boundaries.monthStart),
      sessionInsight
    );
  }

  if (isInPeriod(sessionDate, now, "year")) {
    summary.thisYear = subtractInsights(
      summary.thisYear || createEmptyPeriod(boundaries.yearStart),
      sessionInsight
    );
  }
}

/**
 * Create session insight from tracking session
 */
function createSessionInsight(session: TrackingSession): SessionInsight {
  return {
    totalMiles: session.miles || 0,
    totalDurationInSeconds: session.durationInSeconds || 0,
    totalEarnings: session.earnings || 0,
    totalExpenses: session.expenses || 0,
    sessionCount: 1,
  };
}

/**
 * Add two insights together
 */
function addInsights(
  base: PeriodInsights,
  toAdd: SessionInsight
): PeriodInsights {
  return {
    ...base,
    totalMiles: (base.totalMiles || 0) + (toAdd.totalMiles || 0),
    totalDurationInSeconds:
      (base.totalDurationInSeconds || 0) + (toAdd.totalDurationInSeconds || 0),
    totalEarnings: (base.totalEarnings || 0) + (toAdd.totalEarnings || 0),
    totalExpenses: (base.totalExpenses || 0) + (toAdd.totalExpenses || 0),
    sessionCount: (base.sessionCount || 0) + (toAdd.sessionCount || 0),
  };
}

/**
 * Subtract insights with safety checks
 */
function subtractInsights(
  base: PeriodInsights,
  toSubtract: SessionInsight
): PeriodInsights {
  return {
    ...base,
    totalMiles: Math.max(
      0,
      (base.totalMiles || 0) - (toSubtract.totalMiles || 0)
    ),
    totalDurationInSeconds: Math.max(
      0,
      (base.totalDurationInSeconds || 0) -
        (toSubtract.totalDurationInSeconds || 0)
    ),
    totalEarnings: Math.max(
      0,
      (base.totalEarnings || 0) - (toSubtract.totalEarnings || 0)
    ),
    totalExpenses: Math.max(
      0,
      (base.totalExpenses || 0) - (toSubtract.totalExpenses || 0)
    ),
    sessionCount: Math.max(
      0,
      (base.sessionCount || 0) - (toSubtract.sessionCount || 0)
    ),
  };
}

/**
 * Check if session date falls within current period
 */
function isInPeriod(
  sessionDate: Date,
  currentDate: Date,
  periodType: "day" | "week" | "month" | "year"
): boolean {
  const current = new Date(currentDate);
  const session = new Date(sessionDate);

  switch (periodType) {
    case "day":
      return session.toDateString() === current.toDateString();
    case "week":
      const currentWeekStart = getWeekStart(current);
      const currentWeekEnd = addDays(currentWeekStart, 7);
      return session >= currentWeekStart && session < currentWeekEnd;
    case "month":
      return (
        session.getFullYear() === current.getFullYear() &&
        session.getMonth() === current.getMonth()
      );
    case "year":
      return session.getFullYear() === current.getFullYear();
    default:
      return false;
  }
}

/**
 * Helper function to get period boundaries
 */
function getPeriodBoundaries(date: Date) {
  return {
    today: getToday(date),
    weekStart: getWeekStart(date),
    monthStart: getMonthStart(date),
    yearStart: getYearStart(date),
  };
}

/**
 * Date helper functions
 */
function getToday(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function getWeekStart(date: Date): Date {
  const day = date.getDay();
  const diff = date.getDate() - day + (day === 0 ? -6 : 1); // Monday start
  return new Date(date.getFullYear(), date.getMonth(), diff);
}

function getMonthStart(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), 1);
}

function getYearStart(date: Date): Date {
  return new Date(date.getFullYear(), 0, 1);
}

function addDays(date: Date, days: number): Date {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

/**
 * Create empty summary for new user
 */
function createEmptySummary(userId: string): UserInsightSummary {
  const now = new Date();
  return {
    userId,
    today: createEmptyPeriod(getToday(now)),
    thisWeek: createEmptyPeriod(getWeekStart(now)),
    thisMonth: createEmptyPeriod(getMonthStart(now)),
    thisYear: createEmptyPeriod(getYearStart(now)),
    lastUpdated: Timestamp.now(),
    version: 1,
    validation: {
      lastValidated: Timestamp.now(),
      lastValidatedPeriod: `${now.getFullYear()}-${(now.getMonth() + 1)
        .toString()
        .padStart(2, "0")}`,
      needsValidation: true,
      consecutiveSuccessfulValidations: 0,
    },
  };
}

/**
 * Create empty period insights
 */
function createEmptyPeriod(periodStart: Date): PeriodInsights {
  return {
    totalMiles: 0,
    totalDurationInSeconds: 0,
    totalEarnings: 0,
    totalExpenses: 0,
    sessionCount: 0,
    periodStart: Timestamp.fromDate(periodStart),
    periodEnd: Timestamp.fromDate(periodStart),
  };
}

/**
 * Store failed update for retry
 */
async function storePendingUpdate(
  userId: string,
  sessionId: string,
  sessionData: Record<string, any>,
  updateType: UpdateType,
  errorMessage: string
): Promise<void> {
  try {
    const pendingUpdate: PendingUpdate = {
      userId,
      sessionId,
      sessionData: sessionData || {},
      updateType,
      timestamp: Timestamp.now(),
      retryCount: 0,
      error: errorMessage,
      status: "pending",
    };

    await db.collection("insight-summary-queue").add(pendingUpdate);
    logger.info(
      `Stored pending update for user ${userId}, session ${sessionId}`
    );
  } catch (error) {
    logger.error("Failed to store pending update:", error);
  }
}

/**
 * Callable function for manual retry of failed updates
 */
export const retryFailedInsightUpdates = onCall(
  { cors: true },
  async (request) => {
    // Ensure user is authenticated
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const userId = request.auth.uid;

    try {
      const pendingQuery = await db
        .collection("insight-summary-queue")
        .where("userId", "==", userId)
        .where("status", "==", "pending")
        .limit(10)
        .get();

      const retryPromises = pendingQuery.docs.map(async (doc) => {
        const pendingUpdate = doc.data() as PendingUpdate;

        try {
          // Retry the update - reconstruct the session data
          const sessionData = pendingUpdate.sessionData as TrackingSession;

          await updateSummaryWithRetry(
            pendingUpdate.userId,
            null, // We don't have before state for retries
            sessionData,
            pendingUpdate.updateType,
            pendingUpdate.sessionId
          );

          // Mark as completed
          await doc.ref.update({ status: "completed" });
          logger.info(
            `Successfully retried update for session ${pendingUpdate.sessionId}`
          );
        } catch (error) {
          // Increment retry count
          const newRetryCount = (pendingUpdate.retryCount || 0) + 1;
          await doc.ref.update({
            retryCount: newRetryCount,
            lastRetryError: (error as Error).message,
            status: newRetryCount >= 5 ? "failed" : "pending",
          });
          logger.error(
            `Failed to retry update for session ${pendingUpdate.sessionId}:`,
            error
          );
        }
      });

      await Promise.all(retryPromises);

      return {
        success: true,
        retriedCount: pendingQuery.docs.length,
        message: `Processed ${pendingQuery.docs.length} pending updates`,
      };
    } catch (error) {
      logger.error("Failed to retry insight updates:", error);
      throw new HttpsError("internal", "Failed to retry updates");
    }
  }
);
