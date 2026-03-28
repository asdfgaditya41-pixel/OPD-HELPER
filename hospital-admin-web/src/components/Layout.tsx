import { Outlet, NavLink } from 'react-router-dom';
import { LayoutDashboard, Users, Activity, Settings, LogOut, HeartPulse } from 'lucide-react';

const Layout = () => {
  return (
    <div className="app-container">
      {/* Sidebar Navigation */}
      <aside className="sidebar">
        <div className="logo-container">
          <HeartPulse className="logo-icon" />
          <span className="logo-text">Pulse Admin</span>
        </div>
        
        <nav className="nav-links">
          <NavLink to="/dashboard" className={({isActive}) => `nav-item ${isActive ? 'active' : ''}`}>
            <LayoutDashboard size={20} />
            Overview
          </NavLink>
          <NavLink to="/patients" className={({isActive}) => `nav-item ${isActive ? 'active' : ''}`}>
            <Users size={20} />
            Patients
          </NavLink>
          <NavLink to="/analytics" className={({isActive}) => `nav-item ${isActive ? 'active' : ''}`}>
            <Activity size={20} />
            Analytics
          </NavLink>
          <NavLink to="/settings" className={({isActive}) => `nav-item ${isActive ? 'active' : ''}`}>
            <Settings size={20} />
            Settings
          </NavLink>
        </nav>

        <div style={{ marginTop: 'auto' }}>
          <button className="nav-item" style={{ width: '100%', background: 'none', border: 'none', cursor: 'pointer', textAlign: 'left', color: '#ef4444' }}>
            <LogOut size={20} />
            Log Out
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="main-content">
        <div className="animate-fade-in delay-100">
          <Outlet />
        </div>
      </main>
    </div>
  );
};

export default Layout;
