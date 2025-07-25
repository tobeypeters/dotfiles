export const DEBUG_CONFIG = {
  SHOW_DEBUG: false, // Default to false
  STYLES: `
    .debug-panel {
      background: rgba(0,0,0,0.7);
      position: fixed;
      color: white;
      padding: 2px;
      border-radius: 5px;
      font-size: 0.8rem;
      max-width: 300px;
      z-index: 1000;
    }
    .debug-panel h4 {
      color: #4CAF50;
      margin: 0 0 5px 0;
    }
    .debug-panel ul {
      margin: 0;
      padding-left: 1.2rem;
    }
  `
};

export const DebugPanel = ({ title, data, position = 'top-right' }) => {
  if (!DEBUG_CONFIG.SHOW_DEBUG) return null;

  const positionStyles = {
    'top-right': {
      top: '10px',
      right: '10px',
      bottom: 'auto', // Explicitly reset
    //   maxHeight: '40vh'
    },
    'bottom-right': {
      top: 'auto', // Explicitly reset
      bottom: '10px', // Space for footer
      right: '10px',
    //   maxHeight: '40vh'
    }
  };

  const renderData = (data) => {
    return Object.entries(data).map(([key, value]) => {
      if (typeof value === 'object' && value !== null) {
        return (
          <li key={key}>
            <strong>{key}:</strong>
            <ul style={{ margin: 0, paddingLeft: '1.2rem' }}>
              {renderData(value)}
            </ul>
          </li>
        );
      }
      return (
        <li key={key}>
          <strong>{key}:</strong> {value.toString()}
        </li>
      );
    });
  };

  return (
    <div style={{
      position: 'fixed',
      background: 'rgba(0,0,0,0.7)',
      color: 'white',
      padding: '10px',
      borderRadius: '5px',
      fontSize: '0.8rem',
      maxWidth: '300px',
      overflowY: 'auto',
      zIndex: 1000,
      ...positionStyles[position] // Spread the position styles last
    }}>
      <h4 style={{ margin: '0 0 5px 0', color: '#4CAF50' }}>{title}</h4>
      <ul style={{ margin: 0, paddingLeft: '1.2rem' }}>
        {renderData(data)}
      </ul>
    </div>
  );
};