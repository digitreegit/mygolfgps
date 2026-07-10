import styles from "./page.module.css";

export default function Home() {
  return (
    <main className={styles.main}>
      <div className={styles.hero}>
        <p className={styles.badge}>Apple Watch · US Courses · Free OSM Data</p>
        <h1 className={styles.title}>MyGolfGPS</h1>
        <p className={styles.subtitle}>
          Pick a course. Turn the crown to change holes. See yards to the green.
        </p>
        <ul className={styles.features}>
          <li>Course search from OpenStreetMap</li>
          <li>Manual hole 1–18 navigation</li>
          <li>Live GPS distance on your wrist</li>
          <li>No subscription — just Apple Developer</li>
        </ul>
        <p className={styles.status}>MVP in development · TestFlight coming soon</p>
      </div>

      <section className={styles.api}>
        <h2 className={styles.apiTitle}>API</h2>
        <pre className={styles.codeBlock}>{`GET /api/courses/search?lat=37.77&lon=-122.42&q=pebble
GET /api/courses/{osmType}/{osmId}?name=Course+Name&lat=37.77&lon=-122.42`}</pre>
        <p className={styles.note}>
          Data © <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors (ODbL)
        </p>
      </section>
    </main>
  );
}
