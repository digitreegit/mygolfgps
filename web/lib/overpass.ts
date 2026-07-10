export interface GpsPoint {
  lat: number;
  lon: number;
}

export interface CourseSearchResult {
  id: string;
  name: string;
  location: GpsPoint;
  osmType: "node" | "way" | "relation";
  osmId: number;
  distanceMeters?: number;
}

export interface HoleData {
  number: number;
  greenCenter: GpsPoint | null;
  hasGreen: boolean;
}

export interface CourseData {
  id: string;
  name: string;
  location: GpsPoint;
  holes: HoleData[];
  mappedHoleCount: number;
  totalHoles: number;
  downloadedAt: string;
}

interface OverpassElement {
  type: "node" | "way" | "relation";
  id: number;
  lat?: number;
  lon?: number;
  tags?: Record<string, string>;
  center?: { lat: number; lon: number };
  bounds?: {
    minlat: number;
    minlon: number;
    maxlat: number;
    maxlon: number;
  };
  geometry?: GpsPoint[];
  version?: number;
}

interface OverpassResponse {
  elements: OverpassElement[];
  remark?: string;
}

const OVERPASS_URLS = [
  "https://overpass.kumi.systems/api/interpreter",
  "https://overpass-api.de/api/interpreter",
];
const MIN_REQUEST_INTERVAL_MS = 2100;

let lastRequestTime = 0;
const memoryCache = new Map<string, { data: unknown; expiresAt: number }>();
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;

async function waitForRateLimit(): Promise<void> {
  const elapsed = Date.now() - lastRequestTime;
  const wait = Math.max(0, MIN_REQUEST_INTERVAL_MS - elapsed);
  if (wait > 0) {
    await new Promise((resolve) => setTimeout(resolve, wait));
  }
  lastRequestTime = Date.now();
}

function getCached<T>(key: string): T | null {
  const entry = memoryCache.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    memoryCache.delete(key);
    return null;
  }
  return entry.data as T;
}

function setCache(key: string, data: unknown): void {
  memoryCache.set(key, { data, expiresAt: Date.now() + CACHE_TTL_MS });
}

export async function postOverpass(query: string, retries = 3): Promise<OverpassResponse> {
  const cacheKey = `overpass:${query}`;
  const cached = getCached<OverpassResponse>(cacheKey);
  if (cached) return cached;

  await waitForRateLimit();

  const body = `data=${encodeURIComponent(query)}`;
  let lastError: Error | null = null;

  for (const baseURL of OVERPASS_URLS) {
    try {
      const response = await fetch(baseURL, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "User-Agent": "MyGolfGPS/0.1 (https://mygolfgps.vercel.app; contact@digitreegit.com)",
        },
        body,
        signal: AbortSignal.timeout(15_000),
      });

      const text = await response.text();

      if (!response.ok) {
        if ([429, 502, 503, 504, 406].includes(response.status) && retries > 0) {
          const backoff = 3000 * Math.pow(2, 3 - retries);
          await new Promise((resolve) => setTimeout(resolve, backoff));
          return postOverpass(query, retries - 1);
        }
        lastError = new Error(`Overpass HTTP ${response.status}: ${text.slice(0, 200)}`);
        continue;
      }

      const json = JSON.parse(text) as OverpassResponse;
      if (json.remark?.includes("runtime error")) {
        if (retries > 0) {
          await new Promise((resolve) => setTimeout(resolve, 2000));
          return postOverpass(query, retries - 1);
        }
        throw new Error(json.remark);
      }

      setCache(cacheKey, json);
      return json;
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));
    }
  }

  throw lastError ?? new Error("All Overpass servers failed");
}

export function distanceMeters(a: GpsPoint, b: GpsPoint): number {
  const R = 6_371_000;
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLon = ((b.lon - a.lon) * Math.PI) / 180;
  const lat1 = (a.lat * Math.PI) / 180;
  const lat2 = (b.lat * Math.PI) / 180;
  const x =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(x), Math.sqrt(1 - x));
}

function centroid(points: GpsPoint[]): GpsPoint {
  const lat = points.reduce((s, p) => s + p.lat, 0) / points.length;
  const lon = points.reduce((s, p) => s + p.lon, 0) / points.length;
  return { lat, lon };
}

function pointInPolygon(point: GpsPoint, polygon: GpsPoint[]): boolean {
  if (polygon.length < 3) return false;
  let inside = false;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const xi = polygon[i].lon;
    const yi = polygon[i].lat;
    const xj = polygon[j].lon;
    const yj = polygon[j].lat;
    const intersect =
      yi > point.lat !== yj > point.lat &&
      point.lon < ((xj - xi) * (point.lat - yi)) / (yj - yi) + xi;
    if (intersect) inside = !inside;
  }
  return inside;
}

function elementLocation(el: OverpassElement): GpsPoint {
  if (el.center) return el.center;
  if (el.lat != null && el.lon != null) return { lat: el.lat, lon: el.lon };
  if (el.geometry?.length) return centroid(el.geometry);
  return { lat: 0, lon: 0 };
}

async function geocodePlace(query: string): Promise<GpsPoint | null> {
  const trimmed = query.trim();
  const attempts = [
    `${trimmed}, United States`,
    trimmed.replace(/\bsouth\b/i, "South Carolina") + ", United States",
    "Charleston, South Carolina, United States",
  ].filter((value, index, all) => all.indexOf(value) === index);

  if (/charleston/i.test(trimmed)) {
    attempts.unshift("Charleston, South Carolina, United States");
  }

  for (const searchQ of attempts) {
    const point = await nominatimSearch(searchQ);
    if (point) return point;
  }
  return null;
}

async function nominatimSearch(query: string): Promise<GpsPoint | null> {
  const url = new URL("https://nominatim.openstreetmap.org/search");
  url.searchParams.set("q", query);
  url.searchParams.set("format", "json");
  url.searchParams.set("limit", "1");
  url.searchParams.set("countrycodes", "us");

  const response = await fetch(url, {
    headers: {
      "User-Agent": "MyGolfGPS/0.1 (https://mygolfgps.vercel.app)",
    },
    signal: AbortSignal.timeout(8_000),
  });
  if (!response.ok) return null;

  const results = (await response.json()) as Array<{
    lat: string;
    lon: string;
    class?: string;
    type?: string;
  }>;
  const first =
    results.find((r) => r.class === "place") ??
    results.find((r) => r.type === "city" || r.type === "town") ??
    results[0];
  if (!first) return null;

  return { lat: parseFloat(first.lat), lon: parseFloat(first.lon) };
}

export async function searchCourses(
  query: string | null,
  lat: number,
  lon: number,
  radiusKm = 15
): Promise<CourseSearchResult[]> {
  const cappedRadius = Math.min(Math.max(radiusKm, 5), 25);
  const origin = { lat, lon };

  let searchLat = lat;
  let searchLon = lon;
  let nameFilter = "";

  if (query?.trim()) {
    const geocoded = await geocodePlace(query.trim());
    if (geocoded) {
      searchLat = geocoded.lat;
      searchLon = geocoded.lon;
    } else {
      // Course name: search near the player's GPS with a name filter.
      searchLat = lat;
      searchLon = lon;
      const escaped = query.trim().replace(/"/g, "");
      nameFilter = `["name"~"${escaped}",i]`;
    }
  }

  const latDelta = cappedRadius / 111;
  const lonDelta = cappedRadius / (111 * Math.cos((searchLat * Math.PI) / 180));
  const south = searchLat - latDelta;
  const north = searchLat + latDelta;
  const west = searchLon - lonDelta;
  const east = searchLon + lonDelta;

  const overpassQuery = `
[out:json][timeout:10][bbox:${south},${west},${north},${east}];
(
  node["leisure"="golf_course"]${nameFilter};
  way["leisure"="golf_course"]${nameFilter};
  relation["leisure"="golf_course"]${nameFilter};
);
out center 20;
`;

  const response = await postOverpass(overpassQuery);

  const results = response.elements
    .filter((el) => el.tags?.name)
    .map((el) => {
      const location = elementLocation(el);
      return {
        id: `osm-${el.id}`,
        name: el.tags!.name!,
        location,
        osmType: el.type,
        osmId: el.id,
        distanceMeters: distanceMeters(origin, location),
      } satisfies CourseSearchResult;
    })
    .sort((a, b) => (a.distanceMeters ?? 0) - (b.distanceMeters ?? 0))
    .slice(0, 25);

  return results;
}

function findNearestGreen(
  holeLine: OverpassElement,
  greens: OverpassElement[]
): OverpassElement | null {
  const holeEnd = holeLine.geometry?.at(-1);
  if (!holeEnd) return null;

  let best: OverpassElement | null = null;
  let bestDist = Infinity;

  for (const green of greens) {
    if (!green.geometry?.length) continue;
    const center = centroid(green.geometry);
    const d = distanceMeters(holeEnd, center);
    if (d < bestDist) {
      bestDist = d;
      best = green;
    }
  }

  return bestDist < 120 ? best : null;
}

function buildHoles(
  elements: OverpassElement[],
  anchor: GpsPoint
): HoleData[] {
  const holeLines = elements.filter((el) => el.tags?.golf === "hole");
  const greens = elements.filter((el) => el.tags?.golf === "green");

  const byRef = new Map<number, OverpassElement>();
  for (const line of holeLines) {
    const ref = parseInt(line.tags?.ref ?? "", 10);
    if (!ref) continue;
    const existing = byRef.get(ref);
    if (!existing) {
      byRef.set(ref, line);
      continue;
    }
    const existingTee = existing.geometry?.[0];
    const newTee = line.geometry?.[0];
    if (existingTee && newTee) {
      const existingDist = distanceMeters(anchor, existingTee);
      const newDist = distanceMeters(anchor, newTee);
      if (newDist < existingDist) byRef.set(ref, line);
    }
  }

  const holes: HoleData[] = [];
  for (let n = 1; n <= 18; n++) {
    const line = byRef.get(n);
    if (!line) {
      holes.push({ number: n, greenCenter: null, hasGreen: false });
      continue;
    }

    const green = findNearestGreen(line, greens);
    const greenCenter = green?.geometry?.length
      ? centroid(green.geometry)
      : line.geometry?.at(-1) ?? null;

    holes.push({
      number: n,
      greenCenter,
      hasGreen: greenCenter != null,
    });
  }

  return holes;
}

export async function downloadCourse(
  osmType: string,
  osmId: number,
  name: string,
  playerLat?: number,
  playerLon?: number
): Promise<CourseData> {
  const elementQuery = `
[out:json][timeout:25];
(${osmType}(${osmId}););
out geom;
`;

  const elementResponse = await postOverpass(elementQuery);
  const element = elementResponse.elements.find((el) => el.id === osmId);
  if (!element) throw new Error("Course not found in OSM");

  let bounds = element.bounds;
  if (!bounds && element.geometry?.length) {
    bounds = {
      minlat: Math.min(...element.geometry.map((p) => p.lat)),
      minlon: Math.min(...element.geometry.map((p) => p.lon)),
      maxlat: Math.max(...element.geometry.map((p) => p.lat)),
      maxlon: Math.max(...element.geometry.map((p) => p.lon)),
    };
  }
  if (!bounds) throw new Error("Course has no geometry");

  const { minlat, minlon, maxlat, maxlon } = bounds;
  const geometryQuery = `
[out:json][timeout:25][bbox:${minlat - 0.01},${minlon - 0.01},${maxlat + 0.01},${maxlon + 0.01}];
(
  way["golf"="hole"];
  way["golf"="green"];
);
out geom tags;
`;

  const geometryResponse = await postOverpass(geometryQuery);
  const boundary = element.geometry ?? [];
  const filtered =
    boundary.length >= 3
      ? geometryResponse.elements.filter((el) => {
          if (el.tags?.golf !== "hole") return true;
          const tee = el.geometry?.[0];
          return tee ? pointInPolygon(tee, boundary) : true;
        })
      : geometryResponse.elements;

  const courseLocation: GpsPoint = {
    lat: (minlat + maxlat) / 2,
    lon: (minlon + maxlon) / 2,
  };
  const anchor: GpsPoint =
    playerLat != null && playerLon != null
      ? { lat: playerLat, lon: playerLon }
      : courseLocation;

  const holes = buildHoles(filtered, anchor);
  const mappedHoleCount = holes.filter((h) => h.hasGreen).length;

  return {
    id: `osm-${osmId}`,
    name,
    location: courseLocation,
    holes,
    mappedHoleCount,
    totalHoles: 18,
    downloadedAt: new Date().toISOString(),
  };
}
