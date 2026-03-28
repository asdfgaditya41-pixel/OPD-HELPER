import { Search, Filter, MoreVertical } from 'lucide-react';

const Patients = () => {
  return (
    <div className="animate-fade-in delay-200">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <div>
          <h1>Patient Directory</h1>
          <p>Manage patient records and clinical history.</p>
        </div>
        <button className="btn btn-primary">Add New Patient</button>
      </div>

      <div className="glass-card" style={{ padding: '2rem' }}>
        <div style={{ display: 'flex', gap: '1rem', marginBottom: '2rem' }}>
          <div style={{ flex: 1, position: 'relative' }}>
            <Search size={20} color="var(--text-secondary)" style={{ position: 'absolute', top: '10px', left: '12px' }} />
            <input 
              type="text" 
              placeholder="Search patients by name, ID, or phone number..." 
              style={{
                width: '100%',
                padding: '0.625rem 1rem 0.625rem 2.5rem',
                background: 'rgba(0,0,0,0.2)',
                border: '1px solid var(--border-color)',
                borderRadius: '8px',
                color: 'white',
                fontSize: '0.95rem'
              }}
            />
          </div>
          <button className="btn btn-outline">
            <Filter size={18} />
            Filters
          </button>
        </div>

        <div className="table-container" style={{ marginTop: 0 }}>
          <table>
            <thead>
              <tr>
                <th>Patient</th>
                <th>Contact</th>
                <th>Last Visit</th>
                <th>Condition</th>
                <th>Status</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>
                  <div style={{ display: 'flex', flexDirection: 'column' }}>
                    <span style={{ fontWeight: 600, color: 'white' }}>Sarah Jenkins</span>
                    <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>ID: #PT-8291 • F • 42 yrs</span>
                  </div>
                </td>
                <td>(555) 123-4567</td>
                <td>Today, 09:30 AM</td>
                <td>Hypertension</td>
                <td><span className="status-badge status-stable">Admitted</span></td>
                <td>
                  <button style={{ background: 'transparent', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer' }}>
                    <MoreVertical size={18} />
                  </button>
                </td>
              </tr>
              {/* Add more mock rows if needed */}
              <tr>
                <td>
                  <div style={{ display: 'flex', flexDirection: 'column' }}>
                    <span style={{ fontWeight: 600, color: 'white' }}>Michael Chang</span>
                    <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>ID: #PT-8290 • M • 58 yrs</span>
                  </div>
                </td>
                <td>(555) 987-6543</td>
                <td>Yesterday</td>
                <td>Cardiac Arrhythmia</td>
                <td><span className="status-badge status-warning">Observation</span></td>
                <td>
                  <button style={{ background: 'transparent', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer' }}>
                    <MoreVertical size={18} />
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Patients;
