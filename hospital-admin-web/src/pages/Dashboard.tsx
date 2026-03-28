import { TrendingUp, Users, Activity, PhoneCall } from 'lucide-react';

const Dashboard = () => {
  return (
    <div className="animate-fade-in delay-200">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <div>
          <h1>Hospital Overview</h1>
          <p>Real-time analytics and critical system status.</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <button className="btn btn-outline">Generate Report</button>
          <button className="btn btn-primary">Add Patient</button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="dashboard-grid">
        <div className="glass-card metric-card">
          <div className="metric-header">
            <span>Total Patients</span>
            <Users size={18} color="var(--accent-blue)" />
          </div>
          <div className="metric-value">1,248</div>
          <div className="metric-trend trend-up">
            <TrendingUp size={14} /> +12% this week
          </div>
        </div>

        <div className="glass-card metric-card">
          <div className="metric-header">
            <span>Active Emergencies</span>
            <Activity size={18} color="var(--accent-red)" />
          </div>
          <div className="metric-value" style={{ color: 'var(--accent-red)' }}>4</div>
          <div className="status-badge status-critical" style={{ alignSelf: 'flex-start' }}>Urgent Response</div>
        </div>

        <div className="glass-card metric-card">
          <div className="metric-header">
            <span>Ambulance Dispatches</span>
            <PhoneCall size={18} color="var(--accent-teal)" />
          </div>
          <div className="metric-value">28</div>
          <div className="status-badge status-stable" style={{ alignSelf: 'flex-start' }}>All Units Active</div>
        </div>
      </div>

      {/* Recent Activity Table */}
      <h2 style={{ marginTop: '2.5rem', marginBottom: '1rem' }}>Recent Activity</h2>
      <div className="table-container">
        <table>
          <thead>
            <tr>
              <th>Patient ID</th>
              <th>Name</th>
              <th>Department</th>
              <th>Status</th>
              <th>Time</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td style={{ fontWeight: 500, color: 'var(--accent-blue)' }}>#PT-8291</td>
              <td>Sarah Jenkins</td>
              <td>Cardiology</td>
              <td><span className="status-badge status-stable">Stable</span></td>
              <td style={{ color: 'var(--text-secondary)' }}>10 mins ago</td>
            </tr>
            <tr>
              <td style={{ fontWeight: 500, color: 'var(--accent-blue)' }}>#PT-8290</td>
              <td>Michael Chang</td>
              <td>Emergency</td>
              <td><span className="status-badge status-critical">Critical</span></td>
              <td style={{ color: 'var(--text-secondary)' }}>28 mins ago</td>
            </tr>
            <tr>
              <td style={{ fontWeight: 500, color: 'var(--accent-blue)' }}>#PT-8289</td>
              <td>Elena Rodriguez</td>
              <td>Neurology</td>
              <td><span className="status-badge status-warning">Observation</span></td>
              <td style={{ color: 'var(--text-secondary)' }}>1 hour ago</td>
            </tr>
            <tr>
              <td style={{ fontWeight: 500, color: 'var(--accent-blue)' }}>#PT-8288</td>
              <td>James Wilson</td>
              <td>Orthopedics</td>
              <td><span className="status-badge status-stable">Discharged</span></td>
              <td style={{ color: 'var(--text-secondary)' }}>2 hours ago</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default Dashboard;
