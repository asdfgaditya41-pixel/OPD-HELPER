import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Layout from '/Users/sanyamdhawan/develop/projects/OPD-hELPER1/hospital-admin-web/src/components/Layout';
import Dashboard from '/Users/sanyamdhawan/develop/projects/OPD-hELPER1/hospital-admin-web/src/pages/Dashboard';
import Patients from '/Users/sanyamdhawan/develop/projects/OPD-hELPER1/hospital-admin-web/src/pages/Patients';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<Dashboard />} />
          <Route path="patients" element={<Patients />} />
          <Route path="analytics" element={<Dashboard />} />
          <Route path="settings" element={<Dashboard />} />
          {/* Add more routes here as needed */}
        </Route>
      </Routes>
    </Router>
  );
}

export default App;
