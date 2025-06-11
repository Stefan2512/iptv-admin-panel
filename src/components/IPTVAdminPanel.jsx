import React, { useState, useEffect } from 'react';
import { 
  Users, Server, Play, Radio, Film, Tv, Activity, 
  BarChart3, Settings, Plus, Search, Filter, Download,
  AlertTriangle, CheckCircle, XCircle, Clock, Eye,
  Globe, Wifi, HardDrive, Cpu, MemoryStick, Signal,
  UserCheck, UserX, PlayCircle, Monitor, Smartphone,
  RefreshCw, Database, Loader
} from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, PieChart, Pie, Cell, AreaChart, Area } from 'recharts';

const API_BASE_URL = 'http://95.216.67.55:9999';

const IPTVAdminPanel = () => {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedFilter, setSelectedFilter] = useState('all');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  // Real data states
  const [dashboardData, setDashboardData] = useState({
    totalStreams: 0,
    activeUsers: 0,
    onlineConnections: 0,
    servers: 0,
    totalBandwidth: "0 MB",
    peakConnections: 0
  });

  const [streamStats, setStreamStats] = useState([]);
  const [connectionData, setConnectionData] = useState([]);
  const [servers, setServers] = useState([]);
  const [activeStreams, setActiveStreams] = useState([]);
  const [users, setUsers] = useState([]);
  const [magDevices, setMagDevices] = useState([]);

  // API Functions
  const fetchDashboardData = async () => {
    setLoading(true);
    try {
      const response = await fetch(`${API_BASE_URL}/dashboard`);
      const data = await response.json();
      
      if (response.ok) {
        setDashboardData(data.dashboardData);
        setStreamStats(data.streamStats);
        setConnectionData(data.connectionData);
        setError('');
      } else {
        setError(data.error || 'Failed to fetch dashboard data');
      }
    } catch (err) {
      setError('Failed to connect to API');
      console.error('Dashboard fetch error:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchStreams = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/streams`);
      const data = await response.json();
      
      if (response.ok) {
        setActiveStreams(data);
        setError('');
      } else {
        setError(data.error || 'Failed to fetch streams');
      }
    } catch (err) {
      setError('Failed to fetch streams');
      console.error('Streams fetch error:', err);
    }
  };

  const fetchUsers = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/users`);
      const data = await response.json();
      
      if (response.ok) {
        setUsers(data);
        setError('');
      } else {
        setError(data.error || 'Failed to fetch users');
      }
    } catch (err) {
      setError('Failed to fetch users');
      console.error('Users fetch error:', err);
    }
  };

  const fetchServers = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/servers`);
      const data = await response.json();
      
      if (response.ok) {
        setServers(data);
        setError('');
      } else {
        setError(data.error || 'Failed to fetch servers');
      }
    } catch (err) {
      setError('Failed to fetch servers');
      console.error('Servers fetch error:', err);
    }
  };

  const fetchDevices = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/devices`);
      const data = await response.json();
      
      if (response.ok) {
        setMagDevices(data);
        setError('');
      } else {
        setError(data.error || 'Failed to fetch devices');
      }
    } catch (err) {
      setError('Failed to fetch devices');
      console.error('Devices fetch error:', err);
    }
  };

  // CRUD Operations
  const addUser = async (userData) => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/users`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(userData)
      });
      
      const data = await response.json();
      
      if (response.ok) {
        await fetchUsers();
        setError('');
      } else {
        setError(data.error || 'Failed to add user');
      }
    } catch (err) {
      setError('Failed to add user');
    } finally {
      setLoading(false);
    }
  };

  const updateUser = async (userId, userData) => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/users/${userId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(userData)
      });
      
      const data = await response.json();
      
      if (response.ok) {
        await fetchUsers();
        setError('');
      } else {
        setError(data.error || 'Failed to update user');
      }
    } catch (err) {
      setError('Failed to update user');
    } finally {
      setLoading(false);
    }
  };

  const deleteUser = async (userId) => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/users/${userId}`, {
        method: 'DELETE'
      });
      
      const data = await response.json();
      
      if (response.ok) {
        await fetchUsers();
        setError('');
      } else {
        setError(data.error || 'Failed to delete user');
      }
    } catch (err) {
      setError('Failed to delete user');
    } finally {
      setLoading(false);
    }
  };

  const refreshData = async () => {
    setLoading(true);
    try {
      await Promise.all([
        fetchDashboardData(),
        fetchStreams(),
        fetchUsers(),
        fetchServers(),
        fetchDevices()
      ]);
    } catch (err) {
      setError('Failed to refresh data');
    } finally {
      setLoading(false);
    }
  };

  // Initialize data on component mount
  useEffect(() => {
    refreshData();
  }, []);

  // Auto-refresh data every 30 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      if (activeTab === 'dashboard') {
        fetchDashboardData();
      }
    }, 30000);

    return () => clearInterval(interval);
  }, [activeTab]);

  const getStatusColor = (status) => {
    switch(status) {
      case 'online': case 'active': case 1: return 'text-green-600 bg-green-100';
      case 'offline': case 'expired': case 0: return 'text-gray-600 bg-gray-100';
      case 'maintenance': case 'banned': case -1: return 'text-red-600 bg-red-100';
      default: return 'text-yellow-600 bg-yellow-100';
    }
  };

  const getStatusIcon = (status) => {
    switch(status) {
      case 'online': case 'active': case 1: return <CheckCircle className="w-4 h-4" />;
      case 'offline': case 'expired': case 0: return <XCircle className="w-4 h-4" />;
      case 'maintenance': case 'banned': case -1: return <AlertTriangle className="w-4 h-4" />;
      default: return <Clock className="w-4 h-4" />;
    }
  };

  const getStatusText = (status) => {
    switch(status) {
      case 1: case 'active': case 'online': return 'Active';
      case 0: case 'inactive': case 'offline': return 'Inactive';
      case -1: case 'banned': return 'Banned';
      default: return 'Unknown';
    }
  };

  // Render functions remain the same as before...
  // [Copy all the render functions from the previous version]
  
  return (
    <div className="min-h-screen bg-gray-100">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <div className="flex justify-between items-center">
            <h1 className="text-xl font-bold text-gray-900">IPTV Admin Panel</h1>
            <div className="flex items-center gap-4">
              <button 
                onClick={refreshData}
                className="flex items-center gap-2 text-gray-600 hover:text-gray-900"
                disabled={loading}
              >
                <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
                Refresh
              </button>
              <div className="flex items-center gap-2 bg-green-100 text-green-800 px-3 py-1 rounded-full text-sm">
                <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                Connected to MySQL
              </div>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 py-8">
        {error && (
          <div className="mb-6 bg-red-50 border border-red-200 rounded-md p-4">
            <div className="flex">
              <AlertTriangle className="h-5 w-5 text-red-400" />
              <div className="ml-3">
                <h3 className="text-sm font-medium text-red-800">Error</h3>
                <p className="text-sm text-red-700 mt-1">{error}</p>
              </div>
            </div>
          </div>
        )}

        {/* Navigation Tabs */}
        <div className="mb-8">
          <nav className="flex space-x-1 bg-white rounded-lg p-1 shadow-sm border">
            {[
              { id: 'dashboard', label: 'Dashboard', icon: BarChart3 },
              { id: 'streams', label: 'Streams', icon: Play },
              { id: 'users', label: 'Users', icon: Users },
              { id: 'servers', label: 'Servers', icon: Server },
              { id: 'devices', label: 'Devices', icon: Monitor },
              { id: 'settings', label: 'Settings', icon: Settings },
            ].map((tab) => {
              const IconComponent = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                    activeTab === tab.id
                      ? 'bg-blue-600 text-white'
                      : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
                  }`}
                >
                  <IconComponent className="w-4 h-4" />
                  {tab.label}
                </button>
              );
            })}
          </nav>
        </div>

        {/* Dashboard Content */}
        {activeTab === 'dashboard' && (
          <div className="space-y-6">
            {/* Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
              <div className="bg-white p-6 rounded-lg shadow-sm border">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-600">Total Streams</p>
                    <p className="text-2xl font-bold text-gray-900">
                      {loading ? <Loader className="w-6 h-6 animate-spin" /> : dashboardData.totalStreams.toLocaleString()}
                    </p>
                  </div>
                  <div className="p-3 bg-blue-100 rounded-lg">
                    <Play className="w-6 h-6 text-blue-600" />
                  </div>
                </div>
              </div>

              <div className="bg-white p-6 rounded-lg shadow-sm border">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-600">Active Users</p>
                    <p className="text-2xl font-bold text-gray-900">
                      {loading ? <Loader className="w-6 h-6 animate-spin" /> : dashboardData.activeUsers.toLocaleString()}
                    </p>
                  </div>
                  <div className="p-3 bg-green-100 rounded-lg">
                    <Users className="w-6 h-6 text-green-600" />
                  </div>
                </div>
              </div>

              <div className="bg-white p-6 rounded-lg shadow-sm border">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-600">Online Now</p>
                    <p className="text-2xl font-bold text-gray-900">
                      {loading ? <Loader className="w-6 h-6 animate-spin" /> : dashboardData.onlineConnections.toLocaleString()}
                    </p>
                  </div>
                  <div className="p-3 bg-purple-100 rounded-lg">
                    <Activity className="w-6 h-6 text-purple-600" />
                  </div>
                </div>
              </div>

              <div className="bg-white p-6 rounded-lg shadow-sm border">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-600">Servers</p>
                    <p className="text-2xl font-bold text-gray-900">
                      {loading ? <Loader className="w-6 h-6 animate-spin" /> : dashboardData.servers}
                    </p>
                  </div>
                  <div className="p-3 bg-orange-100 rounded-lg">
                    <Server className="w-6 h-6 text-orange-600" />
                  </div>
                </div>
              </div>

              <div className="bg-white p-6 rounded-lg shadow-sm border">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-600">Bandwidth</p>
                    <p className="text-2xl font-bold text-gray-900">
                      {loading ? <Loader className="w-6 h-6 animate-spin" /> : dashboardData.totalBandwidth}
                    </p>
                  </div>
                  <div className="p-3 bg-red-100 rounded-lg">
                    <Signal className="w-6 h-6 text-red-600" />
                  </div>
                </div>
              </div>

              <div className="bg-white p-6 rounded-lg shadow-sm border">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-600">Peak Today</p>
                    <p className="text-2xl font-bold text-gray-900">
                      {loading ? <Loader className="w-6 h-6 animate-spin" /> : dashboardData.peakConnections.toLocaleString()}
                    </p>
                  </div>
                  <div className="p-3 bg-indigo-100 rounded-lg">
                    <BarChart3 className="w-6 h-6 text-indigo-600" />
                  </div>
                </div>
              </div>
            </div>

            {/* Charts Row */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Connections Chart */}
              <div className="bg-white p-6 rounded-lg shadow-sm border">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Connections Today</h3>
                {connectionData.length > 0 ? (
                  <ResponsiveContainer width="100%" height={300}>
                    <AreaChart data={connectionData}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="time" />
                      <YAxis />
                      <Tooltip />
                      <Area type="monotone" dataKey="connections" stroke="#3B82F6" fill="#3B82F6" fillOpacity={0.3} />
                    </AreaChart>
                  </ResponsiveContainer>
                ) : (
                  <div className="h-300 flex items-center justify-center text-gray-500">
                    <div className="text-center">
                      <Database className="w-12 h-12 mx-auto mb-4 text-gray-300" />
                      <p>Loading connection data...</p>
                    </div>
                  </div>
                )}
              </div>

              {/* Stream Types */}
              <div className="bg-white p-6 rounded-lg shadow-sm border">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Content Distribution</h3>
                {streamStats.length > 0 && streamStats.some(s => s.count > 0) ? (
                  <ResponsiveContainer width="100%" height={300}>
                    <PieChart>
                      <Pie
                        data={streamStats.filter(s => s.count > 0)}
                        cx="50%"
                        cy="50%"
                        outerRadius={100}
                        fill="#8884d8"
                        dataKey="count"
                        label={({ name, value }) => `${name}: ${value}`}
                      >
                        {streamStats.filter(s => s.count > 0).map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.color} />
                        ))}
                      </Pie>
                      <Tooltip />
                    </PieChart>
                  </ResponsiveContainer>
                ) : (
                  <div className="h-300 flex items-center justify-center text-gray-500">
                    <div className="text-center">
                      <Play className="w-12 h-12 mx-auto mb-4 text-gray-300" />
                      <p>Loading stream data...</p>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Active Streams Table */}
            <div className="bg-white rounded-lg shadow-sm border">
              <div className="p-6 border-b border-gray-200">
                <div className="flex justify-between items-center">
                  <h3 className="text-lg font-semibold text-gray-900">Recent Streams</h3>
                  <button 
                    onClick={fetchStreams}
                    className="text-blue-600 hover:text-blue-800 flex items-center gap-2"
                  >
                    <RefreshCw className="w-4 h-4" />
                    Refresh
                  </button>
                </div>
              </div>
              <div className="overflow-x-auto">
                {activeStreams.length > 0 ? (
                  <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Stream Name</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Category</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Added</th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {activeStreams.slice(0, 10).map((stream) => (
                        <tr key={stream.id} className="hover:bg-gray-50">
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="flex items-center">
                              <PlayCircle className="w-5 h-5 text-blue-500 mr-3" />
                              <span className="text-sm font-medium text-gray-900">
                                {stream.stream_display_name || `Stream ${stream.id}`}
                              </span>
                            </div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                              {stream.type_name || 'Unknown'}
                            </span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {stream.category_name || 'Uncategorized'}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(stream.enabled || 1)}`}>
                              {getStatusIcon(stream.enabled || 1)}
                              <span className="ml-1">{getStatusText(stream.enabled || 1)}</span>
                            </span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {stream.added ? new Date(stream.added * 1000).toLocaleDateString() : 'N/A'}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                ) : (
                  <div className="p-12 text-center text-gray-500">
                    <Database className="w-12 h-12 mx-auto mb-4 text-gray-300" />
                    <p>Loading streams from database...</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Other tabs content would go here... */}
        {activeTab !== 'dashboard' && (
          <div className="bg-white rounded-lg shadow-sm border p-12 text-center">
            <p className="text-gray-500">Coming soon: {activeTab} management</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default IPTVAdminPanel;
