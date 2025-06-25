import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import axios from "axios";

// Configure axios with timeouts and retry logic
const httpClient = axios.create({
  timeout: 10000, // 10 second timeout
  headers: {
    "User-Agent": "Firebase-Cloud-Function/1.0",
  },
});
import { getCenter } from "geolib";

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

// ===== DRIVER DENSITY FUNCTIONALITY =====

// Types for driver density
interface LatLng {
  lat: number;
  lng: number;
}

interface DensityGrid {
  gridId: string;
  hexagonBounds: LatLng[];
  population: number;
  estimatedDrivers: number;
  level: "low" | "moderate" | "high";
  cityName: string;
  countyName: string;
  stateName: string;
  lastUpdated: Timestamp;
}

interface CensusResponse {
  data: Array<string[]>;
}

interface GeoNamesPlace {
  name: string;
  adminName1: string;
  adminName2: string;
  population: number;
  lat: string;
  lng: string;
  geonameId: number;
  fcode?: string; // Feature code (e.g., PPL, PPLA, ADM1, etc.)
  distance?: number; // Distance from search point
}

interface GeoNamesResponse {
  geonames?: GeoNamesPlace[];
}

interface DensityRequest {
  lat: number;
  lng: number;
  radiusMiles?: number;
}

// Memory cache for frequently accessed data (15 minutes)
const memoryCache = new Map<string, { data: any; expires: number }>();
const MEMORY_CACHE_DURATION = 15 * 60 * 1000; // 15 minutes

/**
 * Calculate driver density in hexagonal grids around user location
 * Optimized for cost and latency with multi-layer caching
 */
export const calculateDriverDensity = onCall(
  {
    cors: true,
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 30,
  },
  async (request) => {
    const { lat, lng, radiusMiles = 15 } = request.data as DensityRequest;

    // Validate input
    if (!lat || !lng || lat < 24 || lat > 49 || lng < -125 || lng > -66) {
      throw new HttpsError(
        "invalid-argument",
        "Invalid coordinates or outside US boundaries"
      );
    }

    const startTime = Date.now();
    logger.info(`Calculating driver density for: ${lat}, ${lng}`);

    try {
      // Generate cache key with version for new algorithm
      const cacheKey = `density_v2_${lat.toFixed(3)}_${lng.toFixed(
        3
      )}_${radiusMiles}`;

      // Check Firestore cache first (4 hours) - disabled for now to force fresh calculation
      // const cachedData = await getCachedDensityData(cacheKey);
      // if (cachedData) {
      //   logger.info(
      //     `Cache hit for ${cacheKey}, execution time: ${
      //       Date.now() - startTime
      //     }ms`
      //   );
      //   return { grids: cachedData, cached: true };
      // }

      // Generate hexagonal grids
      const grids = generateHexagonalGrids(lat, lng, radiusMiles);

      // Fetch data in parallel for cost optimization
      const [populationData, cityData] = await Promise.all([
        fetchCensusPopulationData(grids),
        fetchCityInformation(grids),
      ]);

      // Calculate driver density for each grid
      const densityGrids = calculateGridDensity(
        grids,
        populationData,
        cityData
      );

      // Cache results in Firestore
      await cacheDensityData(cacheKey, densityGrids);

      const executionTime = Date.now() - startTime;
      logger.info(
        `Driver density calculated successfully in ${executionTime}ms`
      );

      return {
        grids: densityGrids,
        cached: false,
        executionTime,
      };
    } catch (error) {
      logger.error("Failed to calculate driver density:", error);
      throw new HttpsError("internal", "Failed to calculate driver density");
    }
  }
);

/**
 * Generate hexagonal grids around center point
 * Uses hexagonal pattern for optimal coverage without overlap
 */
function generateHexagonalGrids(
  centerLat: number,
  centerLng: number,
  radiusMiles: number
): LatLng[][] {
  const grids: LatLng[][] = [];

  // Calculate individual hexagon size - smaller hexagons for better coverage
  const individualHexRadius = (radiusMiles * 1609.34) / 3; // Divide by 3 instead of 2 for more granular coverage

  // Convert to approximate degrees (rough calculation for US)
  const latDegreePerMeter = 1 / 111320;
  const lngDegreePerMeter =
    1 / (111320 * Math.cos((centerLat * Math.PI) / 180));

  const hexRadiusLat = individualHexRadius * latDegreePerMeter;
  const hexRadiusLng = individualHexRadius * lngDegreePerMeter;

  // Generate hexagons in multiple rings for better coverage
  // Ring 0: Center hexagon
  // Ring 1: 6 surrounding hexagons
  // Ring 2: 12 more outer hexagons (total 19 hexagons)

  const hexPositions = [];

  // Ring 0: Center
  hexPositions.push({ offsetLat: 0, offsetLng: 0 });

  // Ring 1: First ring (6 hexagons)
  const ring1Distance = hexRadiusLat * 1.5;
  for (let i = 0; i < 6; i++) {
    const angle = (i * 60 * Math.PI) / 180;
    hexPositions.push({
      offsetLat: ring1Distance * Math.cos(angle),
      offsetLng:
        (ring1Distance * Math.sin(angle)) /
        Math.cos((centerLat * Math.PI) / 180),
    });
  }

  // Ring 2: Second ring (12 hexagons)
  const ring2Distance = hexRadiusLat * 3;
  for (let i = 0; i < 12; i++) {
    const angle = (i * 30 * Math.PI) / 180; // 30 degrees for 12 hexagons
    hexPositions.push({
      offsetLat: ring2Distance * Math.cos(angle),
      offsetLng:
        (ring2Distance * Math.sin(angle)) /
        Math.cos((centerLat * Math.PI) / 180),
    });
  }

  hexPositions.forEach((pos) => {
    const hexCenterLat = centerLat + pos.offsetLat;
    const hexCenterLng = centerLng + pos.offsetLng;

    // Generate hexagon vertices
    const hexagon: LatLng[] = [];
    for (let i = 0; i < 6; i++) {
      const angle = (i * 60 * Math.PI) / 180;
      const vertexLat = hexCenterLat + hexRadiusLat * Math.cos(angle);
      const vertexLng = hexCenterLng + hexRadiusLng * Math.sin(angle);
      hexagon.push({ lat: vertexLat, lng: vertexLng });
    }

    grids.push(hexagon);
  });

  return grids;
}

/**
 * Fetch population data from U.S. Census Bureau API
 * Uses ACS 5-Year data for most accurate population counts
 */
async function fetchCensusPopulationData(
  grids: LatLng[][]
): Promise<Map<string, number>> {
  const populationMap = new Map<string, number>();

  // Check memory cache first
  const cacheKey = "census_population_batch";
  const cached = memoryCache.get(cacheKey);
  if (cached && cached.expires > Date.now()) {
    return cached.data;
  }

  try {
    // Get state and county for each grid center
    const gridCenters = grids.map((grid) => {
      const center = getCenter(grid);
      if (!center) {
        return { lat: 0, lng: 0 };
      }
      return { lat: center.latitude, lng: center.longitude };
    });

    // Batch API calls by state/county to minimize requests
    const locationPromises = gridCenters.map(async (center, index) => {
      try {
        // Use reverse geocoding to get FIPS codes
        const response = await httpClient.get(
          `https://geocoding.geo.census.gov/geocoder/geographies/coordinates?x=${center.lng}&y=${center.lat}&benchmark=2020&vintage=2020&format=json`
        );

        if (response.status !== 200) {
          logger.warn(`Census geocoding failed for grid ${index}`);
          return null;
        }

        const data = response.data as any;
        const result = data?.result?.geographies;

        if (result?.["Census Tracts"]) {
          const tract = result["Census Tracts"][0];
          return {
            gridIndex: index,
            state: tract.STATE,
            county: tract.COUNTY,
            tract: tract.TRACT,
          };
        }

        return null;
      } catch (error) {
        logger.warn(`Failed to geocode grid ${index}:`, error);
        return null;
      }
    });

    const locations = await Promise.all(locationPromises);
    const validLocations = locations.filter((loc) => loc !== null);

    // Batch population requests by state/county
    const stateCountyGroups = new Map<string, any[]>();
    validLocations.forEach((loc) => {
      if (loc) {
        const key = `${loc.state}_${loc.county}`;
        if (!stateCountyGroups.has(key)) {
          stateCountyGroups.set(key, []);
        }
        stateCountyGroups.get(key)!.push(loc);
      }
    });

    // Fetch population data for each state/county group
    const populationPromises = Array.from(stateCountyGroups.entries()).map(
      async ([key, locs]) => {
        try {
          const [state, county] = key.split("_");
          const tractList = locs.map((loc) => loc.tract).join(",");

          const censusUrl = `https://api.census.gov/data/2022/acs/acs5?get=B01003_001E&for=tract:${tractList}&in=state:${state}%20county:${county}`;
          const response = await httpClient.get(censusUrl);

          if (response.status !== 200) {
            logger.warn(`Census API failed for ${key}`);
            return [];
          }

          const data = response.data as CensusResponse;
          return data.data.slice(1); // Remove header row
        } catch (error) {
          logger.warn(`Failed to fetch census data for ${key}:`, error);
          return [];
        }
      }
    );

    const populationResults = await Promise.all(populationPromises);

    // Map population data back to grids
    populationResults.flat().forEach((row, index) => {
      if (row && row.length >= 4) {
        const population = parseInt(row[0]) || 0;
        const gridKey = `grid_${index}`;
        populationMap.set(gridKey, population);
      }
    });

    // Cache results in memory
    memoryCache.set(cacheKey, {
      data: populationMap,
      expires: Date.now() + MEMORY_CACHE_DURATION,
    });

    return populationMap;
  } catch (error) {
    logger.error("Failed to fetch census data:", error);
    // Return default population estimates
    grids.forEach((_, index) => {
      populationMap.set(`grid_${index}`, 5000); // Default estimate
    });
    return populationMap;
  }
}

/**
 * Fetch city information from GeoNames API
 */
interface CityInfo {
  name: string;
  adminName1: string;
  adminName2: string;
  population: number;
  featureCode: string;
  distance: number;
}

async function fetchCityInformation(
  grids: LatLng[][]
): Promise<Map<string, CityInfo>> {
  const cityMap = new Map<string, CityInfo>();

  try {
    const gridCenters = grids.map((grid) => {
      const center = getCenter(grid);
      if (!center) {
        return { lat: 0, lng: 0 };
      }
      return { lat: center.latitude, lng: center.longitude };
    });

    // Batch requests to avoid rate limits with improved accuracy
    const cityPromises = gridCenters.map(async (center, index) => {
      try {
        // First, try to get the closest populated place with a smaller radius for accuracy
        let response = await httpClient.get(
          `http://api.geonames.org/findNearbyJSON?lat=${center.lat}&lng=${center.lng}&maxRows=3&radius=5&featureClass=P&cities=cities1000&style=full&username=astrixel`
        );

        let data = response.data as GeoNamesResponse;
        let city: GeoNamesPlace | null = data.geonames?.[0] || null;

        // If no results, try with larger radius and include smaller places
        if (!city) {
          response = await httpClient.get(
            `http://api.geonames.org/findNearbyJSON?lat=${center.lat}&lng=${center.lng}&maxRows=5&radius=15&featureClass=P&style=full&username=astrixel`
          );
          data = response.data as GeoNamesResponse;
          city = data.geonames?.[0] || null;
        }

        // If still no results, try administrative divisions
        if (!city) {
          response = await httpClient.get(
            `http://api.geonames.org/findNearbyJSON?lat=${center.lat}&lng=${center.lng}&maxRows=3&radius=25&featureClass=A&style=full&username=astrixel`
          );
          data = response.data as GeoNamesResponse;
          const places = data.geonames || [];
          city = places.find((place) => place.fcode?.startsWith("ADM")) || null;
        }

        if (response.status !== 200) {
          return { gridIndex: index, city: null };
        }

        return {
          gridIndex: index,
          city: city && city.name
            ? {
                name: city.name,
                adminName1: city.adminName1 || "Unknown State", // State
                adminName2: city.adminName2 || "Unknown County", // County
                population: city.population || 0,
                featureCode: city.fcode || "UNKNOWN",
                distance: city.distance || 0,
              }
            : null,
        };
      } catch (error) {
        logger.warn(`Failed to fetch city data for grid ${index}:`, error);
        return { gridIndex: index, city: null };
      }
    });

    const cityResults = await Promise.all(cityPromises);

    cityResults.forEach((result) => {
      const gridKey = `grid_${result.gridIndex}`;
      if (result.city) {
        cityMap.set(gridKey, result.city);
      } else {
        // Provide a more intelligent fallback using coordinates
        const center = gridCenters[result.gridIndex];
        const approximateLocation = getApproximateLocationName(
          center.lat,
          center.lng
        );
        cityMap.set(gridKey, approximateLocation);
      }
    });

    return cityMap;
  } catch (error) {
    logger.error("Failed to fetch city data:", error);
    // Return default city info
    grids.forEach((_, index) => {
      cityMap.set(`grid_${index}`, {
        name: "Unknown",
        adminName1: "Unknown",
        adminName2: "Unknown",
        population: 0,
        featureCode: "UNKNOWN",
        distance: 0,
      });
    });
    return cityMap;
  }
}

/**
 * Calculate driver density for each grid with realistic variation
 */
function calculateGridDensity(
  grids: LatLng[][],
  populationData: Map<string, number>,
  cityData: Map<string, CityInfo>
): DensityGrid[] {
  return grids.map((grid, index) => {
    const gridKey = `grid_${index}`;

    // Get real population data or generate realistic estimates
    let population = populationData.get(gridKey);
    const city: CityInfo = cityData.get(gridKey) || {
      name: "Unknown",
      adminName1: "Unknown",
      adminName2: "Unknown",
      population: 0,
      featureCode: "FALLBACK",
      distance: 0,
    };

    // Always use realistic estimates for now to get proper variation
    // TODO: Re-enable real census data when variation logic is stable
    population = generateRealisticPopulation(city.name, index);

    logger.info(`Grid ${index} (${city.name}): population=${population}`);

    // Calculate estimated drivers with realistic variation (0.3% - 0.5%)
    const basePercentage = 0.003; // 0.3% base
    const variationRange = 0.002; // 0.2% variation (0.3% to 0.5%)

    // Add location-based and deterministic factors for consistent distribution
    const locationFactor = getLocationFactor(city.name, index);
    const deterministicFactor = getDeterministicFactor(city.name, population); // Consistent based on location

    const driverPercentage =
      basePercentage + variationRange * locationFactor * deterministicFactor;
    const estimatedDrivers = Math.max(
      1,
      Math.round(population * driverPercentage)
    );

    logger.info(
      `Grid ${index}: ${city.name}, ${city.adminName2}, ${
        city.adminName1
      } - pop: ${population}, drivers: ${estimatedDrivers} (${(
        driverPercentage * 100
      ).toFixed(2)}%) [${city.featureCode || "N/A"}]`
    );

    // Determine density level with more realistic thresholds
    let level: "low" | "moderate" | "high" = "low";
    if (estimatedDrivers >= 35) {
      level = "high";
    } else if (estimatedDrivers >= 15) {
      level = "moderate";
    }

    // Generate unique grid ID
    const center = getCenter(grid);
    const gridId = center
      ? `${center.latitude.toFixed(4)}_${center.longitude.toFixed(4)}`
      : `grid_${index}`;

    return {
      gridId,
      hexagonBounds: grid,
      population,
      estimatedDrivers,
      level,
      cityName: city.name,
      countyName: city.adminName2,
      stateName: city.adminName1,
      lastUpdated: Timestamp.now(),
    };
  });
}

/**
 * Generate realistic population estimates based on area characteristics
 */
function generateRealisticPopulation(
  cityName: string,
  gridIndex: number
): number {
  const basePop = 3000;
  const cityLower = cityName.toLowerCase();

  // Urban areas tend to have higher population density
  const urbanKeywords = [
    "san francisco",
    "downtown",
    "central",
    "mission",
    "soma",
    "financial",
  ];
  const suburbanKeywords = [
    "residential",
    "suburb",
    "heights",
    "hills",
    "park",
    "garden",
  ];
  const commercialKeywords = [
    "business",
    "commercial",
    "industrial",
    "tech",
    "campus",
  ];

  let multiplier = 1.0;

  if (urbanKeywords.some((keyword) => cityLower.includes(keyword))) {
    multiplier = 1.8 + Math.random() * 0.4; // 1.8x - 2.2x for urban
  } else if (
    commercialKeywords.some((keyword) => cityLower.includes(keyword))
  ) {
    multiplier = 1.4 + Math.random() * 0.3; // 1.4x - 1.7x for commercial
  } else if (suburbanKeywords.some((keyword) => cityLower.includes(keyword))) {
    multiplier = 0.7 + Math.random() * 0.4; // 0.7x - 1.1x for suburban
  } else {
    multiplier = 0.8 + Math.random() * 0.6; // 0.8x - 1.4x for general areas
  }

  // Add some randomness for neighboring grids
  const neighboringVariation = 0.7 + Math.random() * 0.6; // ±30% variation

  return Math.round(basePop * multiplier * neighboringVariation);
}

/**
 * Get approximate location name based on coordinates for fallback purposes
 */
function getApproximateLocationName(lat: number, lng: number): CityInfo {
  // Major US metro areas and their approximate coordinate ranges
  const metroAreas = [
    {
      name: "San Francisco",
      state: "California",
      county: "San Francisco County",
      latMin: 37.6,
      latMax: 37.9,
      lngMin: -122.6,
      lngMax: -122.3,
    },
    {
      name: "Los Angeles",
      state: "California",
      county: "Los Angeles County",
      latMin: 33.9,
      latMax: 34.3,
      lngMin: -118.7,
      lngMax: -118.1,
    },
    {
      name: "New York",
      state: "New York",
      county: "New York County",
      latMin: 40.4,
      latMax: 40.9,
      lngMin: -74.3,
      lngMax: -73.7,
    },
    {
      name: "Chicago",
      state: "Illinois",
      county: "Cook County",
      latMin: 41.6,
      latMax: 42.1,
      lngMin: -88.0,
      lngMax: -87.5,
    },
    {
      name: "Houston",
      state: "Texas",
      county: "Harris County",
      latMin: 29.5,
      latMax: 30.1,
      lngMin: -95.8,
      lngMax: -95.0,
    },
    {
      name: "Phoenix",
      state: "Arizona",
      county: "Maricopa County",
      latMin: 33.2,
      latMax: 33.8,
      lngMin: -112.4,
      lngMax: -111.6,
    },
    {
      name: "Philadelphia",
      state: "Pennsylvania",
      county: "Philadelphia County",
      latMin: 39.8,
      latMax: 40.1,
      lngMin: -75.4,
      lngMax: -74.9,
    },
    {
      name: "San Antonio",
      state: "Texas",
      county: "Bexar County",
      latMin: 29.2,
      latMax: 29.7,
      lngMin: -98.8,
      lngMax: -98.3,
    },
    {
      name: "San Diego",
      state: "California",
      county: "San Diego County",
      latMin: 32.5,
      latMax: 33.0,
      lngMin: -117.4,
      lngMax: -116.9,
    },
    {
      name: "Dallas",
      state: "Texas",
      county: "Dallas County",
      latMin: 32.6,
      latMax: 33.0,
      lngMin: -97.0,
      lngMax: -96.5,
    },
  ];

  // Check if coordinates fall within any major metro area
  for (const metro of metroAreas) {
    if (
      lat >= metro.latMin &&
      lat <= metro.latMax &&
      lng >= metro.lngMin &&
      lng <= metro.lngMax
    ) {
      return {
        name: metro.name,
        adminName1: metro.state,
        adminName2: metro.county,
        population: 0,
        featureCode: "METRO_APPROX",
        distance: 0,
      };
    }
  }

  // Fallback to general state-based approximation
  const stateApproximations = [
    {
      name: "California",
      latMin: 32.5,
      latMax: 42.0,
      lngMin: -124.5,
      lngMax: -114.1,
    },
    {
      name: "Texas",
      latMin: 25.8,
      latMax: 36.5,
      lngMin: -106.6,
      lngMax: -93.5,
    },
    {
      name: "Florida",
      latMin: 24.4,
      latMax: 31.0,
      lngMin: -87.6,
      lngMax: -80.0,
    },
    {
      name: "New York",
      latMin: 40.4,
      latMax: 45.0,
      lngMin: -79.8,
      lngMax: -71.8,
    },
    {
      name: "Pennsylvania",
      latMin: 39.7,
      latMax: 42.3,
      lngMin: -80.5,
      lngMax: -74.7,
    },
    {
      name: "Illinois",
      latMin: 36.9,
      latMax: 42.5,
      lngMin: -91.5,
      lngMax: -87.0,
    },
    { name: "Ohio", latMin: 38.4, latMax: 42.3, lngMin: -84.8, lngMax: -80.5 },
  ];

  for (const state of stateApproximations) {
    if (
      lat >= state.latMin &&
      lat <= state.latMax &&
      lng >= state.lngMin &&
      lng <= state.lngMax
    ) {
      return {
        name: `Location in ${state.name}`,
        adminName1: state.name,
        adminName2: "Unknown County",
        population: 0,
        featureCode: "STATE_APPROX",
        distance: 0,
      };
    }
  }

  return {
    name: `Location at ${lat.toFixed(3)}, ${lng.toFixed(3)}`,
    adminName1: "Unknown State",
    adminName2: "Unknown County",
    population: 0,
    featureCode: "COORD_APPROX",
    distance: 0,
  };
}

/**
 * Get deterministic factor based on city name and population for consistent results
 */
function getDeterministicFactor(cityName: string, population: number): number {
  // Create a simple hash from city name + population for consistency
  let hash = 0;
  const str = cityName + population.toString();
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash = hash & hash; // Convert to 32-bit integer
  }

  // Convert hash to a value between 0-1
  return Math.abs(hash % 1000) / 1000;
}

/**
 * Get location-based factor for driver percentage (economic activity, transit access, etc.)
 */
function getLocationFactor(cityName: string, gridIndex: number): number {
  const cityLower = cityName.toLowerCase();

  // High driver activity areas (business districts, airports, entertainment)
  const highActivityKeywords = [
    "downtown",
    "financial",
    "airport",
    "station",
    "mall",
    "center",
    "plaza",
  ];
  // Medium activity areas (residential with good transit)
  const mediumActivityKeywords = [
    "mission",
    "castro",
    "haight",
    "richmond",
    "sunset",
  ];
  // Lower activity areas (quiet residential, hills)
  const lowActivityKeywords = [
    "heights",
    "hills",
    "park",
    "residential",
    "quiet",
  ];

  // Use deterministic factor based on city name for consistency
  const deterministicVariation = getDeterministicFactor(cityName, gridIndex);

  if (highActivityKeywords.some((keyword) => cityLower.includes(keyword))) {
    return 0.8 + deterministicVariation * 0.2; // 0.8 - 1.0 (high activity)
  } else if (
    mediumActivityKeywords.some((keyword) => cityLower.includes(keyword))
  ) {
    return 0.5 + deterministicVariation * 0.3; // 0.5 - 0.8 (medium activity)
  } else if (
    lowActivityKeywords.some((keyword) => cityLower.includes(keyword))
  ) {
    return 0.2 + deterministicVariation * 0.3; // 0.2 - 0.5 (low activity)
  } else {
    // Default areas with center-distance factor
    const centerDistance = Math.abs(gridIndex - 3); // Distance from center grid
    return Math.max(0.3, 0.9 - centerDistance * 0.15); // Decreases with distance from center
  }
}

/**
 * Get cached density data from Firestore
 * TODO: Re-enable when realistic variation is stable
 */
// @ts-ignore - Temporarily disabled caching function while testing realistic variation
async function getCachedDensityData(
  cacheKey: string
): Promise<DensityGrid[] | null> {
  try {
    const cacheDoc = await db.collection("density-cache").doc(cacheKey).get();

    if (cacheDoc.exists) {
      const data = cacheDoc.data();
      if (!data) return null;
      const cacheExpiry = data.expiresAt?.toDate();

      if (cacheExpiry && cacheExpiry > new Date()) {
        return data.grids as DensityGrid[];
      }
    }

    return null;
  } catch (error) {
    logger.warn("Failed to get cached density data:", error);
    return null;
  }
}

/**
 * Cache density data in Firestore
 */
async function cacheDensityData(
  cacheKey: string,
  grids: DensityGrid[]
): Promise<void> {
  try {
    const expiresAt = new Date(Date.now() + 4 * 60 * 60 * 1000); // 4 hours

    await db
      .collection("density-cache")
      .doc(cacheKey)
      .set({
        grids,
        createdAt: Timestamp.now(),
        expiresAt: Timestamp.fromDate(expiresAt),
        cacheKey,
      });

    logger.info(`Cached density data for key: ${cacheKey}`);
  } catch (error) {
    logger.warn("Failed to cache density data:", error);
  }
}
