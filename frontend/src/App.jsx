import { useEffect, useState } from "react";
import { Link, Route, Routes } from "react-router-dom";

// Relative path: served through the same CloudFront domain, so no mixed-content issues.
const API_BASE = "/api/v1";

function Dashboard() {
  const [health, setHealth] = useState("checking...");

  useEffect(() => {
    fetch(`${API_BASE}/health`)
      .then((r) => r.json())
      .then((d) => setHealth(d.status))
      .catch(() => setHealth("unreachable"));
  }, []);

  return (
    <section>
      <h2>Dashboard</h2>
      <p>API health: {health}</p>
    </section>
  );
}

function Profile() {
  return (
    <section>
      <h2>Profile</h2>
    </section>
  );
}

export default function App() {
  return (
    <main>
      <h1>StartTech</h1>
      <nav>
        <Link to="/dashboard">Dashboard</Link> | <Link to="/profile">Profile</Link>
      </nav>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/profile" element={<Profile />} />
      </Routes>
    </main>
  );
}
