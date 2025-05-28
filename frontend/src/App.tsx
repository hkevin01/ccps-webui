import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import { Dashboard } from './pages/Dashboard';

const About: React.FC = () => (
  <div className="container mt-4">
    <h2>About</h2>
    <p>This project predicts and visualizes the likelihood of coastal changes based on environmental data, climate models, and historical trends.</p>
  </div>
);

const UserSettings: React.FC = () => (
  <div className="container mt-4">
    <h2>User Settings</h2>
    <p>Manage your user preferences and role-based features here.</p>
  </div>
);

const App: React.FC = () => (
  <Router>
    <nav className="navbar navbar-expand-lg navbar-light bg-light">
      <div className="container-fluid">
        <Link className="navbar-brand" to="/">Coastal Change</Link>
        <button className="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
          <span className="navbar-toggler-icon"></span>
        </button>
        <div className="collapse navbar-collapse" id="navbarNav">
          <ul className="navbar-nav">
            <li className="nav-item">
              <Link className="nav-link" to="/">Dashboard</Link>
            </li>
            <li className="nav-item">
              <Link className="nav-link" to="/about">About</Link>
            </li>
            <li className="nav-item">
              <Link className="nav-link" to="/settings">User Settings</Link>
            </li>
          </ul>
        </div>
      </div>
    </nav>
    <Routes>
      <Route path="/" element={<Dashboard />} />
      <Route path="/about" element={<About />} />
      <Route path="/settings" element={<UserSettings />} />
    </Routes>
  </Router>
);

export default App;
